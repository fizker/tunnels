import Vapor

extension Response {
	convenience init(html: String) {
		self.init(
			headers: ["content-type": "text/html"],
			body: .init(string: html)
		)
	}
}
