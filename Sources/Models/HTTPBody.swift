import Foundation

public enum HTTPBody: Codable, Sendable {
	case binary(Data)
	case text(String)
}
