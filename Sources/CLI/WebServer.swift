import Foundation

/// Start a web server synchronously to serve the files in the given directory.
///
/// This function will exit when the user sends a SIGINT signal (Ctrl+C).
func startWebserverSync(port: Int, publicDirectory: URL) throws {
  // Example usage:
  let _ = try runPythonWith(arguments: [
    "-m", "http.server", String(port), "-d", publicDirectory.path,
  ], port: port)
}

func runPythonWith(arguments: [String], port: Int) throws -> String {
  let task = Process()
  let pipe = Pipe()

  task.standardOutput = pipe
  task.standardError = pipe
  task.arguments = arguments
  task.executableURL = URL(fileURLWithPath: try findPythonExecutable())
  task.standardInput = nil

  // Set the termination handler to kill the child process when the parent is terminated



  let signalSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
  signal(SIGINT, SIG_IGN)  // Ignore default handling
  signalSource.setEventHandler {
    print("\nExiting...")
    signalSource.cancel()
    task.terminate()
    exit(0)
  }

  // Start monitoring the signal
  signalSource.resume()


  try task.run()

  print("Server running at http://localhost:" + port.description)
  task.waitUntilExit()
  return ""
}

struct PythonNotFound: CustomStringConvertible, Error {
  var description: String { "python executable not found. Try adding it to PATH." }
}
struct NoPathFoundError: CustomStringConvertible, Error {
  var description: String { "PATH environment variable not found!" }
}

func findPythonExecutable() throws -> String {
  // Get the environment's PATH variable
  guard let path = ProcessInfo.processInfo.environment["PATH"] else {
    throw NoPathFoundError()
  }

  // Split the PATH into individual directories
  let directories = path.components(separatedBy: ":")

  // Check each directory for the 'python' executable
  for directory in directories {
    #if os(Windows)
      let pythonPath = (directory as NSString).appendingPathComponent("python3.exe")
    #else
      let pythonPath = (directory as NSString).appendingPathComponent("python3")
    #endif

    if FileManager.default.isExecutableFile(atPath: pythonPath) {
      return pythonPath
    }
  }
  throw PythonNotFound()
}
