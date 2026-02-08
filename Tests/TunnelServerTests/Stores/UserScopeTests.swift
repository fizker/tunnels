import Testing
@testable import TunnelServer

struct UserScopeTests {
	typealias Scope = User.Scope

	@Test
	func sorted__allCases__sortIsStable() async throws {
		for _ in 0..<100 {
			#expect(Set(Scope.allCases).sorted() == [
				.sysadmin,
				.admin,
				.setupRead,
			])
		}
	}
}
