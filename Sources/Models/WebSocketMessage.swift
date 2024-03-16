/// A message sent from the Client via WebSocket.
public enum WebSocketClientMessage: Codable, Sendable {
	case response(HTTPResponse)
	case addTunnel(TunnelConfiguration)
	case removeTunnel(host: String)
}

/// A message sent from the Server via WebSocket.
public enum WebSocketServerMessage: Codable, Sendable {
	/// Sent when an incoming request was registered with the server. This expects a ``WebSocketClientMessage/response(_:)`` to follow in reasonable time.
	case request(HTTPRequest)
	case error(TunnelError)
	/// Sent as acknowledgement for ``WebSocketClientMessage/addTunnel(_:)``.
	case tunnelAdded(TunnelConfiguration)
	/// Sent as acknowledgement for ``WebSocketClientMessage/removeTunnel(host:)``.
	case tunnelRemoved(TunnelConfiguration)
}
