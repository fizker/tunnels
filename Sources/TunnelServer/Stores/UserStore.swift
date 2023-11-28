struct User {
	var username: String
}

actor UserStore {
	func user(username: String, password: String) -> User? {
		if username == "admin" && password == "1234" {
			User(username: "admin")
		} else {
			nil
		}
	}
}
