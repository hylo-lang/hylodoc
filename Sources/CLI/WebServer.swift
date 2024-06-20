import Logging
import NIOCore
import NIOPosix
import Vapor

/// Start a web server asynchronously to serve the files in the given directory.
func startWebServer(port: Int = 8080, publicDirectory: URL) async throws {
  var env = Environment(name: "development", arguments: ["vapor"])
  try LoggingSystem.bootstrap(from: &env)

  let app = try await Application.make(env)
  app.http.server.configuration.port = port
  defer { app.shutdown() }

  app.middleware.use(
    FileMiddleware(
      publicDirectory: publicDirectory.absoluteURL.path,
      defaultFile: "index.html"
    )
  )

  try await app.execute()
  try await app.asyncShutdown()
}

/// Start a web server synchronously to serve the files in the given directory.
/// 
/// This function will exit when the user sends a SIGINT signal (Ctrl+C).
func startWebserverSync(port: Int, publicDirectory: URL) throws {
  // Set up signal handler for SIGINT (Ctrl+C)
  let signalSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
  signal(SIGINT, SIG_IGN)  // Ignore default handling
  signalSource.setEventHandler {
    print("Exiting...")
    signalSource.cancel()
    exit(0)
  }
  // Start monitoring the signal
  signalSource.resume()

  // Run the task asynchronously
  Task {
    try await startWebServer(port: port, publicDirectory: publicDirectory)
  }

  // Keep the run loop running
  RunLoop.main.run()
}
