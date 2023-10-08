import Foundation

public enum HTTPBody: Codable {
	case binary(Data)
	case text(String)
}
