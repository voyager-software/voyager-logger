import Testing
import Foundation
@testable import VoyagerLogger

struct RollingFileDestinationTests {
    // MARK: Internal

    @Test
    func `creates log directory on init`() throws {
        let dir = FileManager.default.temporaryDirectory
            .appending(component: "VoyagerLoggerTests-\(UUID().uuidString)")
        defer { cleanup(dir) }

        let config = RollingFileDestination.Configuration(directory: dir)
        _ = try RollingFileDestination(configuration: config)

        #expect(FileManager.default.fileExists(atPath: dir.path))
    }

    @Test
    func `writes log entries to disk`() async throws {
        let dir = try makeTempDir()
        defer { cleanup(dir) }

        let config = RollingFileDestination.Configuration(directory: dir)
        let dest = try RollingFileDestination(configuration: config)
        dest.info("hello from test")

        // Give the async Task time to write
        try await Task.sleep(for: .milliseconds(500))

        let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "log" }
        #expect(!files.isEmpty)

        let content = try String(contentsOf: files[0], encoding: .utf8)
        #expect(content.contains("hello from test"))
    }

    @Test
    func `filters messages below minimum level`() async throws {
        let dir = try makeTempDir()
        defer { cleanup(dir) }

        let config = RollingFileDestination.Configuration(directory: dir, minimumLevel: .warning)
        let dest = try RollingFileDestination(configuration: config)
        dest.debug("should be skipped")
        dest.warning("should appear")

        try await Task.sleep(for: .milliseconds(500))

        let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "log" }

        if let file = files.first {
            let content = try String(contentsOf: file, encoding: .utf8)
            #expect(!content.contains("should be skipped"))
            #expect(content.contains("should appear"))
        }
    }

    @Test
    func `rotates when file size limit is exceeded`() async throws {
        let dir = try makeTempDir()
        defer { cleanup(dir) }

        // Use a tiny size limit to trigger rotation.
        // Rotation filenames use second-precision timestamps, so we sleep
        // between bursts to ensure distinct file names.
        let config = RollingFileDestination.Configuration(directory: dir, maxFileSizeBytes: 50)
        let dest = try RollingFileDestination(configuration: config)

        dest.info("First message that exceeds the fifty byte limit easily")
        try await Task.sleep(for: .milliseconds(1100))

        dest.info("Second message written after a pause to get a new filename")
        try await Task.sleep(for: .milliseconds(500))

        let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "log" }
        #expect(files.count > 1)
    }

    @Test
    func `prunes old archives beyond maxArchivedFiles`() async throws {
        let dir = try makeTempDir()
        defer { cleanup(dir) }

        let config = RollingFileDestination.Configuration(
            directory: dir,
            maxFileSizeBytes: 10, // tiny to force rotation
            maxArchivedFiles: 2
        )
        let dest = try RollingFileDestination(configuration: config)

        for i in 0 ..< 20 {
            dest.info("Msg \(i) padded with text to exceed the tiny limit easily")
        }

        try await Task.sleep(for: .milliseconds(1500))

        let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "log" }
        #expect(files.count <= 2)
    }

    // MARK: Private

    private func makeTempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appending(component: "VoyagerLoggerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func cleanup(_ dir: URL) {
        try? FileManager.default.removeItem(at: dir)
    }
}
