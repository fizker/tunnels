/// A message sent from the Client via WebSocket.
public enum WebSocketClientMessage: Codable {
	case response(HTTPResponse)
	case addTunnel(TunnelConfiguration)
	case removeTunnel(host: String)
}

/// A message sent from the Server via WebSocket.
public enum WebSocketServerMessage: Codable {
	case request(HTTPRequest)
	case error(TunnelError)
}
