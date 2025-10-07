struct VaporErrorResponse<Reason: Codable>: Codable {
	/// Always `true` to indicate this is a non-typical JSON response.
	var error: Bool

	/// The reason for the error.
	var reason: Reason
}

extension VaporErrorResponse {
	init(from decoder: any Decoder) throws {
		let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
		self.error = try container.decode(Bool.self, forKey: .error)
		guard error
		else {
			throw DecodingError.dataCorruptedError(
				forKey: .error,
				in: container,
				debugDescription: #""error" must be "true" for error responses."#,
			)
		}
		self.reason = try container.decode(Reason.self, forKey: .reason)
	}
}
