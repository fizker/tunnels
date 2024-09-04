package struct PendingChallenge {
	/// The full URL where the challenge must be published. **Must** be simple HTTP over port 80.
	public let endpoint: String

	/// The exact value that the `endpoint` must return over HTTP on port 80.
	public var value: String

	/// The status of the challenge.
	public var status: Status = .pending

	public enum Status {
		/// The challenge is pending a request.
		case pending
		/// The challenge has been requested by LetsEncrypt.
		case requested
	}
}
