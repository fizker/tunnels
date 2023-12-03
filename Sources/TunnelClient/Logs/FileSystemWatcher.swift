import Foundation

public class FileSystemWatcher {
	deinit {
		stop()
	}

	public typealias Callback = (_ directoryWatcher: FileSystemWatcher) -> Void

	public convenience init(watching path: String, callback: @escaping Callback) throws {
		self.init()

		try watch(path: path, callback: callback)
	}

	private var dirFD: Int32 = -1 {
		didSet {
			if oldValue != -1 {
				close(oldValue)
			}
		}
	}
	private var dispatchSource : (any DispatchSourceFileSystemObject)?

	public func watch(path: String, callback: @escaping Callback) throws {
		// Open the directory
		dirFD = open(path, O_EVTONLY)
		guard dirFD >= 0
		else { throw Error.couldNotOpenPath }

		// Create and configure a DispatchSource to monitor it
		let dispatchSource = DispatchSource.makeFileSystemObjectSource(
			fileDescriptor: dirFD,
			eventMask: .write
		)
		dispatchSource.setEventHandler { [unowned self] in
			callback(self)
		}
		dispatchSource.setCancelHandler { [unowned self] in
			self.dirFD = -1
		}
		self.dispatchSource = dispatchSource

		// Start monitoring
		dispatchSource.activate()
	}

	public func stop() {
		dispatchSource?.cancel()
		dispatchSource = nil
	}

	enum Error: Swift.Error {
		case couldNotOpenPath
	}
}
