import WebURL

extension WebURL {
	func appending(path: some Collection<String>) -> WebURL {
		var url = self
		url.pathComponents.append(contentsOf: path)
		return url
	}
}
