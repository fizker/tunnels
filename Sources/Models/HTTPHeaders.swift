public struct HTTPHeaders: Codable {
	struct Header: Codable, Equatable {
		var name: String
		var normalizedName: String
		var values: [String]

		init(name: String, values: [String]) {
			self.name = name
			self.normalizedName = Self.normalize(name)
			self.values = values
		}

		static func normalize(_ name: String) -> String {
			name.lowercased()
		}

		static func ==(lhs: Self, rhs: Self) -> Bool {
			lhs.normalizedName == rhs.normalizedName && lhs.values == rhs.values
		}
	}

	var values: [String: Header]

	public init(_ values: [String : [String]] = [:]) {
		self.values = [:]
		for (name, values) in values {
			let header = Header(name: name, values: values)
			self.values[header.normalizedName] = header
		}
	}

	public init(_ values: [String : String]) {
		self.init(values.mapValues { [$0] })
	}

	public mutating func set(value: String, for name: String) {
		let header = Header(name: name, values: [value])
		values[header.normalizedName] = header
	}

	public mutating func add(value: String, for name: String) {
		var values = headers(named: name)
		values.append(value)
		let header = Header(name: name, values: values)
		self.values[header.normalizedName] = header
	}

	public func firstHeader(named name: String) -> String? {
		headers(named: name).first
	}

	public func headers(named name: String) -> [String] {
		values[Header.normalize(name)]?.values ?? []
	}

	public func map<T>(_ transform: (String, [String]) throws -> T) rethrows -> [T] {
		try values.map { _, header in
			try transform(header.name, header.values)
		}
	}
}
