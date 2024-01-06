public struct HTTPHeaders: Codable, Sequence {
	public func makeIterator() -> IndexingIterator<[(String, [String])]> {
		values.map { ($0.key, $0.value.values) }.makeIterator()
	}

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

	public mutating func remove(value: String, for name: String) {
		var values = headers(named: name)
		values.removeAll { $0 == value }
		let header = Header(name: name, values: values)
		self.values[header.normalizedName] = values.isEmpty ? nil : header
	}

	public mutating func removeAll(named name: String) {
		values[Header.normalize(name)] = nil
	}

	public func firstHeader(named name: String) -> String? {
		headers(named: name).first
	}

	public func headers(named name: String) -> [String] {
		values[Header.normalize(name)]?.values ?? []
	}

	fileprivate enum CodingKeys: String, CodingKey {
		case values
	}
}

extension HTTPHeaders {
	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let values = try container.decode([String: [String]].self, forKey: .values)

		self.init(values)
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		let values = Dictionary(uniqueKeysWithValues: self.values.map { ($0.value.name, $0.value.values) })
		try container.encode(values, forKey: .values)
	}
}
