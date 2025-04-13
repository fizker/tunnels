import Common
public import Foundation
import Logging
import System
import TunnelModels
public import WebURL
import WebURLFoundationExtras

public actor LogStorage {
	/// The max filesize that we want to put directly into the log.json file.
	private let maxInlinedFileSize: UInt64 = 100_000

	private let logger = Logger(label: "LogStorage")
	private(set) public var summaries: [LogSummary] = []
	private var logs: [Log.ID: Log] = [:]
	private let storagePath: WebURL
	private let summaryURL: WebURL
	private let summaryPath: String
	private let coder = Coder()
	private let fileManager: FileManager = .default
	private var listener: FileSystemWatcher?

	public init(storagePath: String) async throws {
		var path = FilePath(storagePath).lexicallyNormalized()
		if path.isRelative {
			path = FilePath(FileManager.default.currentDirectoryPath + "/" + path.string)
		}
		try await self.init(storage: WebURL(filePath: path.string))
	}

	public init(storage: WebURL) async throws {
		let summaryURL = storage.appending(path: ["summary.json"])
		let summaryPath = summaryURL.path

		self.storagePath = storage
		self.summaryURL = summaryURL
		self.summaryPath = summaryPath

		try fileManager.createDirectory(
			at: storagePath,
			withIntermediateDirectories: true
		)

		readSummaryFile()

		deleteOldLogs()
	}

	@discardableResult
	private func readSummaryFile() -> [LogSummary] {
		if let data = fileManager.contents(atPath: summaryPath) {
			do {
				summaries = try coder.decode(data)
				return summaries
			} catch {
				summaries = []
				logger.error("Failed to decode summary.json", metadata: [
					"error": "\(error)",
					"path": "\(summaryPath)",
				])
			}
		}

		return summaries
	}

	public func listenForUpdates(onUpdate: @Sendable @escaping ([LogSummary]) async -> Void) throws {
		guard listener == nil
		else { return }

		logger.info("Starting listener")
		listener = try FileSystemWatcher(watching: summaryPath) { [weak self] _ in
			guard let self
			else { return }

			Task {
				self.logger.info("Summary was updated")
				await onUpdate(await self.readSummaryFile())
			}
		}
	}

	struct TemporaryLog {
		var logID: Log.ID
		var requestStream: WebURL
		var responseStream: WebURL
	}

	/// Adds the given log to disk and updates the summary data.
	///
	/// - returns: A URL for the position in the log folder where temporary streaming-data can be stored.
	func add(_ log: Log) -> TemporaryLog? {
		summaries.append(.init(log: log))
		logs[log.id] = log

		defer { deleteOldLogs() }

		do {
			let logFolder = try write(log)
			return .init(
				logID: log.id,
				requestStream: logFolder.appending(path: ["request-stream"]),
				responseStream: logFolder.appending(path: ["response-stream"])
			)
		} catch {
			logger.error("Failed to write log", metadata: [
				"error": "\(error)",
				"logID": "\(log.id)",
			])
			return nil
		}
	}

	/// Updates the current log
	func update(_ log: Log) {
		summaries.removeAll { $0.id == log.id }
		_ = add(log)
	}

	/// Updates the log after the body has finished streaming.
	///
	/// If the data is small enough and text-based, it will be stored directly in the log file.
	/// Otherwise, a reference to where the data is stored will be put in the log instead.
	///
	/// - parameters tempLog: The log to update.
	func update(_ tempLog: TemporaryLog) throws {
		guard var log = logs[tempLog.logID]
		else { return }

		var hadUpdate = false
		if let size = size(of: tempLog.requestStream) {
			hadUpdate = true
			if size <= maxInlinedFileSize {
				log.requestBody = .included
				let contentType = log.request.headers.firstHeader(named: "content-type")
				log.request.body = try consumeTemporaryFile(at: tempLog.requestStream, contentType: contentType)
			} else {
				// Maybe rename the file to have reasonable extension based on content-type?
				log.requestBody = .separate(filename: tempLog.requestStream.pathComponents.last!)
			}
		}
		if let size = size(of: tempLog.responseStream) {
			hadUpdate = true
			if size <= maxInlinedFileSize {
				log.responseBody = .included
				let contentType = log.response?.headers.firstHeader(named: "content-type")
				log.response?.body = try consumeTemporaryFile(at: tempLog.responseStream, contentType: contentType)
			} else {
				// Maybe rename the file to have reasonable extension based on content-type?
				log.responseBody = .separate(filename: tempLog.responseStream.pathComponents.last!)
			}
		}

		if hadUpdate {
			_ = try write(log)
		}
	}

	private func consumeTemporaryFile(at streamFile: WebURL, contentType: String?) throws -> HTTPBody {
		let data = try Data(contentsOf: streamFile)
		let foo: HTTPBody
		if
			let contentType,
			contentType.hasPrefix("text") || contentType.hasPrefix("application/json"),
			let value = String(data: data, encoding: .utf8)
		{
			foo = .text(value)
		} else {
			foo = .binary(data)
		}
		try fileManager.removeItem(at: streamFile)

		return foo
	}

	private func size(of file: WebURL) -> UInt64? {
		guard let handle = FileHandle(forReadingAtPath: file.path)
		else { return nil }
		defer { try! handle.close() }

		return try! handle.seekToEnd()
	}

	public func log(id: Log.ID) -> Log? {
		if let log = logs[id] {
			return log
		}

		let path = storagePath.appending(path: [id.uuidString, "log.json"])
		guard let data = fileManager.contents(atPath: path.path)
		else { return nil }

		do {
			let log = try coder.decode(Log.self, from: data)
			logs[id] = log
			return log
		} catch {
			logger.error("Failed to read log", metadata: [
				"logID": "\(id)",
				"error": "\(error)",
			])
			return nil
		}
	}

	/// Writes the log to disk. It also updates the summary file with the new log.
	///
	/// - parameter log: The log to write.
	/// - returns: The folder that contains the log data.
	private func write(_ log: Log) throws -> WebURL {
		let logFolder = storagePath.appending(path: [log.id.uuidString])
		try fileManager.createDirectory(
			at: logFolder,
			withIntermediateDirectories: true
		)

		let data = try coder.encode(log)
		fileManager.createFile(
			at: logFolder.appending(path: ["log.json"]),
			contents: data
		)

		try writeSummaryData()

		return logFolder
	}

	private func writeSummaryData() throws {
		let summaryData = try coder.encode(summaries)
		fileManager.createFile(
			atPath: summaryPath,
			contents: summaryData
		)
	}

	private func deleteOldLogs() {
		do {
			let expirationDate = Date(timeIntervalSinceNow: -84_600)
			let toDelete = summaries.filter { $0.responseSent ?? $0.requestReceived < expirationDate }
			summaries = summaries.filter { expirationDate <= $0.responseSent ?? $0.requestReceived }

			for log in toDelete {
				let logFolder = storagePath.appending(path: [log.id.uuidString])
				try fileManager.removeItem(at: logFolder)
			}

			try writeSummaryData()
		} catch {
			logger.error("Failed to remove old logs", metadata: [
				"error": "\(error)",
			])
		}
	}
}

extension FileManager {
	@discardableResult
	func createFile(at url: WebURL, contents: Data?) -> Bool {
		return createFile(atPath: url.path, contents: contents)
	}

	func removeItem(at url: WebURL) throws {
		return try removeItem(at: URL(url)!)
	}

	func createDirectory(
		at url: WebURL,
		withIntermediateDirectories createIntermediates: Bool,
		attributes: [FileAttributeKey : Any]? = nil
	) throws {
		try createDirectory(at: URL(url)!, withIntermediateDirectories: createIntermediates, attributes: attributes)
	}
}
