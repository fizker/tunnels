import Binary
import Foundation

struct DNSPacket: Equatable {
	var header: Header
	var questions: [QuestionRecord] = []
	var answers: [ResourceRecord] = []

	init(header: Header, questions: [QuestionRecord], answers: [ResourceRecord]) {
		self.header = header
		self.questions = questions
		self.answers = answers
	}

	init(iterator: inout BitIterator) throws {
		guard let header = Header(iterator: &iterator)
		else { throw ParseError.endOfStream }

		self.header = header

		for _ in 0..<header.questionCount {
			try questions.append(.init(iterator: &iterator))
		}

		for _ in 0..<header.answerCount {
			try answers.append(.init(iterator: &iterator))
		}
	}

	var asData: Data {
		var output = header.asData
		questions.forEach { output.append($0.asData()) }
		answers.forEach { output.append($0.asData()) }
		return output
	}
}
