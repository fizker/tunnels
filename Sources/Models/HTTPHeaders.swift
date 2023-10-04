public struct HTTPHeaders: Codable {
	private var values: [String: [String]]

	public init(_ values: [String : [String]] = [:]) {
		self.values = values
	}

	public init(_ values: [String : String]) {
		self.values = values.mapValues { [$0] }
	}

	public mutating func set(value: String, for name: String) {
		values[name] = [value]
	}

	public mutating func add(value: String, for name: String) {
		var values = headers(named: name)
		values.append(value)
		self.values[name] = values
	}

	public func firstHeader(named name: String) -> String? {
		headers(named: name).first
	}

	public func headers(named name: String) -> [String] {
		values[name] ?? []
	}
}
