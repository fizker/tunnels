public actor LogStorage {
	private(set) var summaries: [LogSummary] = []
	private var logs: [Log.ID: Log] = [:]
	private var storagePath: String

	public init(storagePath: String) {
		self.storagePath = storagePath
	}

	func add(_ log: Log) {
		summaries.append(.init(log: log))
		logs[log.id] = log
	}

	func log(id: Log.ID) -> Log? {
		logs[id]
	}
}
