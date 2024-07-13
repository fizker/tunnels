import ACME
import Common
import Foundation
import NIOSSL

let pi = ProcessInfo.processInfo

guard pi.arguments.count > 1
else {
	print("Error: Path to data file is required")
	exit(1)
}

let fileName = pi.arguments[1]

let fm = FileManager.default
guard let data = fm.contents(atPath: fileName)
else {
	print("Error: Failed to load data at \(fileName)")
	exit(1)
}

let coder = Coder()

guard
	let oldData = try? coder.decode(OldACMEData.self, from: data),
	let oldCert = oldData.certificate
else {
	let newData = try? coder.decode(ACMEData.self, from: data)
	if newData == nil {
		print("Error: Data is neither compatible with new or old format")
		exit(1)
	} else {
		print("Data is already compatible")
		exit(0)
	}
}

let convertedACMEData = try convert(oldData: oldData, oldCert: oldCert)
let convertedData = try coder.encode(convertedACMEData)
try fm.moveItem(atPath: fileName, toPath: fileName + ".backup")
fm.createFile(atPath: fileName, contents: convertedData)
