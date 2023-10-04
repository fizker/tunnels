import Foundation
import TunnelsClient

print("server says \(try await hello())")

if let id = ProcessInfo().arguments.dropFirst().first.flatMap(UUID.init(uuidString:)) {
	try await connect(id: id)
	try await Task.sleep(for: .seconds(120))
}
