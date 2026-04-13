//
//  LogFileExporter.swift
//  VoyagerLogger
//
//  Created by Gábor Sajó on 2026-04-09.
//

import Foundation

public struct LogFileExporter: Sendable {
    // MARK: Lifecycle

    public init(directory: URL) {
        self.directory = directory
    }

    // MARK: Public

    public enum ExportError: Error, LocalizedError {
        case noLogFiles

        // MARK: Public

        public var errorDescription: String? {
            switch self {
            case .noLogFiles: "No log files found to export."
            }
        }
    }

    /// Returns all log file URLs sorted newest-first.
    public func availableLogFiles() throws -> [URL] {
        try FileManager.default.logFiles(in: self.directory)
    }

    /// Merges all log files into a single Data payload, oldest entries first.
    public func exportedData() throws -> Data {
        let files = try self.availableLogFiles()
        return try files.reduce(into: Data()) { result, url in
            try result.append(Data(contentsOf: url))
        }
    }

    /// Writes merged logs to a temp file and returns its URL (suitable for UIActivityViewController / NSSharingServicePicker).
    public func exportedFileURL() throws -> URL {
        let data = try exportedData()
        let dest = FileManager.default.temporaryDirectory
            .appending(component: "logs_\(Int(Date().timeIntervalSince1970))_\(UUID().uuidString.prefix(8)).log")
        try data.write(to: dest)
        return dest
    }

    /// Creates a zip archive of all log files and returns it as Data.
    public func exportedZipData() throws -> Data {
        let files = try self.availableLogFiles()
        guard !files.isEmpty else { throw ExportError.noLogFiles }
        return try ZIPArchiver.archive(files: files)
    }

    // MARK: Private

    private let directory: URL
}

public extension FileManager {
    /// Returns `.log` files in the given directory, sorted oldest-first (chronological).
    ///
    /// Uses creation date as primary sort key with filename as tiebreaker
    /// for files created within the same second.
    func logFiles(in directory: URL) throws -> [URL] {
        try contentsOfDirectory(at: directory, includingPropertiesForKeys: [.creationDateKey])
            .filter { $0.pathExtension == "log" }
            .sorted {
                let d1 = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                let d2 = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                if d1 != d2 { return d1 < d2 }
                return $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
            }
    }
}
