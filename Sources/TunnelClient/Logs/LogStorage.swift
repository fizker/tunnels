import Common
import Foundation
import Logging
import WebURL
import WebURLFoundationExtras

public actor LogStorage {
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
		try await self.init(storage: WebURL(filePath: storagePath))
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

	func add(_ log: Log) {
		summaries.append(.init(log: log))
		logs[log.id] = log

		do {
			try write(log)
		} catch {
			logger.error("Failed to write log", metadata: [
				"error": "\(error)",
				"logID": "\(log.id)",
			])
		}

		deleteOldLogs()
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

	private func write(_ log: Log) throws {
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
