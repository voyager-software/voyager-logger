import Testing
import Foundation
@testable import VoyagerLogger

struct LogFileExporterTests {
    // MARK: Internal

    @Test
    func `availableLogFiles returns only .log files`() async throws {
        let dir = try makeTempDir()
        defer { cleanup(dir) }

        try self.createLogFile(in: dir, name: "app.log", content: "log data")
        try "not a log".write(to: dir.appending(component: "readme.txt"), atomically: true, encoding: .utf8)

        let exporter = LogFileExporter(directory: dir)
        let files = try await exporter.availableLogFiles()

        #expect(files.count == 1)
        #expect(files[0].lastPathComponent == "app.log")
    }

    @Test
    func `availableLogFiles returns empty array for empty directory`() async throws {
        let dir = try makeTempDir()
        defer { cleanup(dir) }

        let exporter = LogFileExporter(directory: dir)
        let files = try await exporter.availableLogFiles()
        #expect(files.isEmpty)
    }

    @Test
    func `exportedData merges all log files`() async throws {
        let dir = try makeTempDir()
        defer { cleanup(dir) }

        try self.createLogFile(in: dir, name: "first.log", content: "AAA\n")
        try self.createLogFile(in: dir, name: "second.log", content: "BBB\n")

        let exporter = LogFileExporter(directory: dir)
        let data = try await exporter.exportedData()
        let merged = try #require(String(data: data, encoding: .utf8))

        #expect(merged.contains("AAA"))
        #expect(merged.contains("BBB"))
    }

    @Test
    func `exportedFileURL writes to a temp file`() async throws {
        let dir = try makeTempDir()
        defer { cleanup(dir) }

        try self.createLogFile(in: dir, name: "test.log", content: "content\n")

        let exporter = LogFileExporter(directory: dir)
        let url = try await exporter.exportedFileURL()
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(FileManager.default.fileExists(atPath: url.path))
        let content = try String(contentsOf: url, encoding: .utf8)
        #expect(content.contains("content"))
    }

    @Test
    func `exportedZipURL creates a valid zip file`() async throws {
        let dir = try makeTempDir()
        defer { cleanup(dir) }

        try self.createLogFile(in: dir, name: "a.log", content: "Hello from log A\n")
        try self.createLogFile(in: dir, name: "b.log", content: "Hello from log B\n")

        let exporter = LogFileExporter(directory: dir)
        let zipURL = try await exporter.exportedZipURL()
        defer { try? FileManager.default.removeItem(at: zipURL) }

        #expect(zipURL.pathExtension == "zip")
        #expect(FileManager.default.fileExists(atPath: zipURL.path))

        // Verify it starts with a ZIP local file header signature (PK\x03\x04)
        let zipData = try Data(contentsOf: zipURL)
        #expect(zipData.count > 4)
        #expect(zipData[0] == 0x50) // 'P'
        #expect(zipData[1] == 0x4B) // 'K'
        #expect(zipData[2] == 0x03)
        #expect(zipData[3] == 0x04)
    }

    @Test
    func `exportedZipURL is extractable and preserves file contents`() async throws {
        let dir = try makeTempDir()
        defer { cleanup(dir) }

        try self.createLogFile(in: dir, name: "a.log", content: "Content of A\n")
        try self.createLogFile(in: dir, name: "b.log", content: "Content of B\n")

        let exporter = LogFileExporter(directory: dir)
        let zipURL = try await exporter.exportedZipURL()
        defer { try? FileManager.default.removeItem(at: zipURL) }

        // Extract using /usr/bin/ditto via posix_spawn (works on Mac Catalyst)
        let extractDir = FileManager.default.temporaryDirectory
            .appending(component: "VoyagerExporterExtract-\(UUID().uuidString)")
        defer { cleanup(extractDir) }

        let exitCode = runCommand("/usr/bin/ditto", arguments: ["-xk", zipURL.path, extractDir.path])
        #expect(exitCode == 0)

        let extractedA = try String(contentsOf: extractDir.appending(component: "a.log"), encoding: .utf8)
        let extractedB = try String(contentsOf: extractDir.appending(component: "b.log"), encoding: .utf8)
        #expect(extractedA == "Content of A\n")
        #expect(extractedB == "Content of B\n")
    }

    // MARK: - Integration with RollingFileDestination

    @Test
    func `exports real log files written by RollingFileDestination`() async throws {
        let dir = try makeTempDir()
        defer { cleanup(dir) }

        let config = RollingFileDestination.Configuration(directory: dir, minimumLevel: .debug)
        let dest = try RollingFileDestination(configuration: config)

        dest.info("Integration test message one")
        dest.error("Integration test message two")
        try await Task.sleep(for: .milliseconds(500))

        let exporter = LogFileExporter(directory: dir)
        let files = try await exporter.availableLogFiles()
        #expect(!files.isEmpty)

        let data = try await exporter.exportedData()
        let merged = try #require(String(data: data, encoding: .utf8))
        #expect(merged.contains("Integration test message one"))
        #expect(merged.contains("Integration test message two"))
    }

    @Test
    func `exports real log files to a text file`() async throws {
        let dir = try makeTempDir()
        defer { cleanup(dir) }

        let config = RollingFileDestination.Configuration(directory: dir)
        let dest = try RollingFileDestination(configuration: config)

        dest.warning("Exported warning")
        try await Task.sleep(for: .milliseconds(500))

        let exporter = LogFileExporter(directory: dir)
        let url = try await exporter.exportedFileURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let content = try String(contentsOf: url, encoding: .utf8)
        #expect(content.contains("Exported warning"))
        #expect(content.contains("WRN"))
    }

    @Test
    func `zips real log files and extracts them successfully`() async throws {
        let dir = try makeTempDir()
        defer { cleanup(dir) }

        let config = RollingFileDestination.Configuration(directory: dir, filePrefix: "integration")
        let dest = try RollingFileDestination(configuration: config)

        dest.info("Zipped log entry alpha")
        dest.error("Zipped log entry beta")
        try await Task.sleep(for: .milliseconds(500))

        let exporter = LogFileExporter(directory: dir)
        let zipURL = try await exporter.exportedZipURL()
        defer { try? FileManager.default.removeItem(at: zipURL) }

        // Extract and verify
        let extractDir = FileManager.default.temporaryDirectory
            .appending(component: "VoyagerIntegrationExtract-\(UUID().uuidString)")
        defer { cleanup(extractDir) }

        let exitCode = runCommand("/usr/bin/ditto", arguments: ["-xk", zipURL.path, extractDir.path])
        #expect(exitCode == 0)

        // Find the extracted log file(s)
        let extracted = try FileManager.default.contentsOfDirectory(at: extractDir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "log" }
        #expect(!extracted.isEmpty)
        #expect(extracted[0].lastPathComponent.hasPrefix("integration_"))

        let content = try String(contentsOf: extracted[0], encoding: .utf8)
        #expect(content.contains("Zipped log entry alpha"))
        #expect(content.contains("Zipped log entry beta"))
    }

    @Test
    func `exportedZipURL throws noLogFiles when directory is empty`() async throws {
        let dir = try makeTempDir()
        defer { cleanup(dir) }

        let exporter = LogFileExporter(directory: dir)
        await #expect(throws: LogFileExporter.ExportError.noLogFiles) {
            try await exporter.exportedZipURL()
        }
    }

    // MARK: Private

    private func makeTempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appending(component: "VoyagerExporterTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func cleanup(_ dir: URL) {
        try? FileManager.default.removeItem(at: dir)
    }

    private func createLogFile(in dir: URL, name: String, content: String) throws {
        let url = dir.appending(component: name)
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Runs an executable via posix_spawn (works on Mac Catalyst unlike Process).
    @discardableResult
    private func runCommand(_ path: String, arguments: [String]) -> Int32 {
        var pid: pid_t = 0
        let argv = ([path] + arguments).map { strdup($0) } + [nil]
        defer { argv.compactMap { $0 }.forEach { free($0) } }
        let status = posix_spawn(&pid, path, nil, nil, argv, nil)
        guard status == 0 else { return -1 }
        var exitStatus: Int32 = 0
        waitpid(pid, &exitStatus, 0)
        return (exitStatus >> 8) & 0xFF
    }
}
