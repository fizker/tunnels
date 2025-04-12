import Common
public import Foundation
import Logging
import System
public import WebURL
import WebURLFoundationExtras

public actor LogStorage {
	/// The max filesize that we want to put directly into the log.json file.
	private let maxInlinedFileSize: UInt64 = 1024 * 1024

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

	typealias TemporaryLog = (tempStorage: WebURL, logID: Log.ID)

	/// Adds the given log to disk and updates the summary data.
	///
	/// - returns: A URL for the position in the log folder where temporary streaming-data can be stored.
	func add(_ log: Log) -> TemporaryLog? {
		summaries.append(.init(log: log))
		logs[log.id] = log

		defer { deleteOldLogs() }

		do {
			return (try write(log).appending(path: ["streamed-data"]), log.id)
		} catch {
			logger.error("Failed to write log", metadata: [
				"error": "\(error)",
				"logID": "\(log.id)",
			])
			return nil
		}
	}

	/// Updates the log after the body has finished streaming.
	///
	/// If the data is small enough (small enough JSON response?), it will be stored directly in the log file.
	/// Otherwise, a reference to where the data is stored will be put in the log instead.
	///
	/// - parameters tempLog: The log to update.
	func update(_ tempLog: TemporaryLog) throws {
		guard
			var log = logs[tempLog.logID],
			let size = size(of: tempLog.tempStorage.path)
		else { return }

		if size <= maxInlinedFileSize {
			log.responseBody = .included
			let data = try Data(contentsOf: tempLog.tempStorage)
			let contentType = log.response.headers.firstHeader(named: "content-type")
			if
				contentType?.hasPrefix("text/plain") ?? false,
				let value = String(data: data, encoding: .utf8)
			{
				log.response.body = .text(value)
			} else {
				log.response.body = .binary(data)
			}
			try fileManager.removeItem(at: tempLog.tempStorage)
		} else {
			// Maybe rename the file to have reasonable extension based on content-type?
			log.responseBody = .separate(filename: tempLog.tempStorage.pathComponents.last!)
		}

		_ = try write(log)
	}

	private func size(of file: String) -> UInt64? {
		guard let handle = FileHandle(forReadingAtPath: file)
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
			let toDelete = summaries.filter { $0.responseSent < expirationDate }
			summaries = summaries.filter { expirationDate <= $0.responseSent }

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
