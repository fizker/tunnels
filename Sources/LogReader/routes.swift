import Foundation
import Vapor

func routes(_ app: Application) throws {
	app.get { req in
		Response(
			headers: ["content-type": "text/html"],
			body: """
			<!doctype html>
			Hello world!
			"""
		)
	}
}
