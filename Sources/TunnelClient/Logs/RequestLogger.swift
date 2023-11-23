actor RequestLogger {
	private(set) var summaries: [LogSummary] = []
	private var logs: [Log.ID: Log] = [:]

	func add(log: Log) {
		summaries.append(.init(log: log))
		logs[log.id] = log
	}

	func log(id: Log.ID) -> Log? {
		logs[id]
	}
}
