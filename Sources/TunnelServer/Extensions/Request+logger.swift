import Logging
import Vapor

extension Request {
	func logger(file: String = #fileID, function: String = #function) -> LabelledLogger {
		LabelledLogger(logger: logger, metadata: [
			"file": .string(file),
			"func": .string(function),
		])
	}

	func logger(label: String, file: String = #fileID, function: String = #function) -> LabelledLogger {
		LabelledLogger(logger: logger, metadata: [
			"label": .string(label),
			"file": .string(file),
			"func": .string(function),
		])
	}
}

struct LabelledLogger {
	var logger: Logger
	var metadata: Logger.Metadata

	func info(_ message: Logger.Message) {
		log(level: .info, message)
	}

	func warning(_ message: Logger.Message) {
		log(level: .warning, message)
	}

	func trace(_ message: Logger.Message) {
		log(level: .trace, message)
	}

	func debug(_ message: Logger.Message) {
		log(level: .debug, message)
	}

	func notice(_ message: Logger.Message) {
		log(level: .notice, message)
	}

	func error(_ message: Logger.Message) {
		log(level: .error, message)
	}

	func critical(_ message: Logger.Message) {
		log(level: .critical, message)
	}

	func log(level: Logger.Level, _ message: Logger.Message) {
		logger.log(level: level, message, metadata: metadata)
	}
}
