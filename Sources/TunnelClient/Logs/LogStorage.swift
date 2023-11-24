import Foundation
import Logging

public actor LogStorage {
	private let logger = Logger(label: "LogStorage")
	private(set) var summaries: [LogSummary] = []
	private var logs: [Log.ID: Log] = [:]
	private let storagePath: URL
	private let encoder: JSONEncoder = .init()
	private let decoder: JSONDecoder = .init()
	private let fileManager: FileManager = .default

	public init(storagePath: String) throws {
		try self.init(storagePath: URL(filePath: storagePath))
	}

	public init(storagePath: URL) throws {
		self.storagePath = storagePath

		encoder.outputFormatting = [
			.prettyPrinted,
			.sortedKeys,
			.withoutEscapingSlashes,
		]
		encoder.dateEncodingStrategy = .iso8601

		try fileManager.createDirectory(
			at: storagePath,
			withIntermediateDirectories: true
		)
	}

	func add(_ log: Log) {
		summaries.append(.init(log: log))
		logs[log.id] = log

		do {
			try write(log)
		} catch {
			logger.error("Failed to write log", metadata: [
				"error": .string(error.localizedDescription),
				"logID": .string(log.id.uuidString),
			])
		}
	}

	func log(id: Log.ID) -> Log? {
		logs[id]
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
			at: storagePath.appending(path: "summary.json"),
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
