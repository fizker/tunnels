/// A message sent from the Client via WebSocket.
public enum WebSocketClientMessage: Codable {
	case response(HTTPResponse)
}

/// A message sent from the Server via WebSocket.
public enum WebSocketServerMessage: Codable {
	case request(HTTPRequest)
	case error(TunnelError)
}
