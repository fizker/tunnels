import Foundation
import Logging

public actor LogStorage {
	private let logger = Logger(label: "LogStorage")
	private(set) var summaries: [LogSummary] = []
	private var logs: [Log.ID: Log] = [:]
	private let storagePath: URL
	private let summaryURL: URL
	private let summaryPath: String
	private let encoder: JSONEncoder = .init()
	private let decoder: JSONDecoder = .init()
	private let fileManager: FileManager = .default

	public init(storagePath: String) throws {
		try self.init(storage: URL(filePath: storagePath))
	}

	public init(storage: URL) throws {
		let summaryURL = storage.appending(path: "summary.json")
		let summaryPath = summaryURL.path

		self.storagePath = storage
		self.summaryURL = summaryURL
		self.summaryPath = summaryPath

		encoder.outputFormatting = [
			.prettyPrinted,
			.sortedKeys,
			.withoutEscapingSlashes,
		]
		encoder.dateEncodingStrategy = .iso8601

		decoder.dateDecodingStrategy = .iso8601

		try fileManager.createDirectory(
			at: storagePath,
			withIntermediateDirectories: true
		)

		if let data = fileManager.contents(atPath: summaryPath) {
			do {
				summaries = try decoder.decode([LogSummary].self, from: data)
			} catch {
				logger.error("Failed to decode summary.json", metadata: [
					"error": "\(error)",
					"path": "\(summaryPath)",
				])
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
	}

	func log(id: Log.ID) -> Log? {
		if let log = logs[id] {
			return log
		}

		let path = storagePath
			.appending(path: id.uuidString)
			.appending(path: "log.json")
		guard let data = fileManager.contents(atPath: path.path())
		else { return nil }

		do {
			let log = try decoder.decode(Log.self, from: data)
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
		let logFolder = storagePath.appending(path: log.id.uuidString)
		try fileManager.createDirectory(
			at: logFolder,
			withIntermediateDirectories: true
		)

		let data = try encoder.encode(log)
		fileManager.createFile(
			at: logFolder.appending(path: "log.json"),
			contents: data
		)

		let summaryData = try encoder.encode(summaries)
		fileManager.createFile(
			atPath: summaryPath,
			contents: summaryData
		)
	}
}

extension FileManager {
	@discardableResult
	func createFile(at url: URL, contents: Data?) -> Bool {
		return createFile(atPath: url.path, contents: contents)
	}
}
