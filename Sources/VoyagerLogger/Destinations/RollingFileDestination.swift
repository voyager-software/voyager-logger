//
//  RollingFileDestination.swift
//  VoyagerLogger
//
//  Created by Gábor Sajó on 2026-04-09.
//

import Foundation

public actor RollingFileDestination: LogDestination {
    // MARK: Lifecycle

    public init(configuration: Configuration) throws {
        self.config = configuration
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        self.fileNameFormatter = DateFormatter()
        self.fileNameFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"

        try FileManager.default.createDirectory(at: configuration.directory, withIntermediateDirectories: true)
    }

    // MARK: Public

    public struct Configuration: Sendable {
        // MARK: Lifecycle

        public init(
            directory: URL,
            filePrefix: String = "app",
            maxFileSizeBytes: Int = 5 * 1024 * 1024, // 5 MB
            maxFileAge: TimeInterval = 60 * 60 * 24, // 24 h
            maxArchivedFiles: Int = 5,
            minimumLevel: LogLevel = .debug
        ) {
            self.directory = directory
            self.filePrefix = filePrefix
            self.maxFileSizeBytes = maxFileSizeBytes
            self.maxFileAge = maxFileAge
            self.maxArchivedFiles = maxArchivedFiles
            self.minimumLevel = minimumLevel
        }

        // MARK: Public

        public let filePrefix: String
        public let maxFileSizeBytes: Int
        public let maxFileAge: TimeInterval
        public let maxArchivedFiles: Int
        public let minimumLevel: LogLevel
        public let directory: URL
    }

    // MARK: - LogDestination

    public nonisolated func log(level: LogLevel, message: @autoclosure () -> String, meta: LogMetadata, file: String, function: String, line: Int) {
        guard level >= self.config.minimumLevel else { return }
        let entry = LogEntry(level: level, message: message(), file: file, function: function, line: line)
        Task { await self.write(entry) }
    }

    // MARK: Private

    private struct LogEntry: Sendable {
        let level: LogLevel
        let message: String
        let file: String
        let function: String
        let line: Int
        let date: Date = .now
    }

    // MARK: - State

    private let config: Configuration
    private var fileHandle: FileHandle?
    private var currentFileURL: URL?
    private var currentFileSize: Int = 0
    private var fileOpenedAt: Date = .distantPast
    private let dateFormatter: DateFormatter
    private let fileNameFormatter: DateFormatter

    private func write(_ entry: LogEntry) {
        let timestamp = self.dateFormatter.string(from: entry.date)
        let line = "[\(timestamp)] \(entry.level.label) \(entry.file):\(entry.line) \(entry.message)\n"

        do {
            try self.ensureFileReady()
            guard let handle = fileHandle, let data = line.data(using: .utf8) else { return }
            try handle.write(contentsOf: data)
            self.currentFileSize += data.count
        }
        catch {
            // Intentionally swallow — logging must never crash the app
        }
    }

    private func ensureFileReady() throws {
        let needsRotation = self.fileHandle == nil
            || self.currentFileSize >= self.config.maxFileSizeBytes
            || Date().timeIntervalSince(self.fileOpenedAt) >= self.config.maxFileAge

        if needsRotation {
            try self.rotate()
        }
    }

    private func rotate() throws {
        // Close current handle
        try self.fileHandle?.close()
        self.fileHandle = nil

        // Open new file
        let name = "\(config.filePrefix)_\(fileNameFormatter.string(from: .now)).log"
        let url = self.config.directory.appending(component: name)
        FileManager.default.createFile(atPath: url.path, contents: nil)
        self.fileHandle = try FileHandle(forWritingTo: url)
        self.currentFileURL = url
        self.currentFileSize = 0
        self.fileOpenedAt = .now

        // Prune old archives
        try self.pruneArchives()
    }

    private func pruneArchives() throws {
        let fm = FileManager.default
        let files = try fm.contentsOfDirectory(at: self.config.directory, includingPropertiesForKeys: [.creationDateKey])
            .filter { $0.pathExtension == "log" }
            .sorted {
                let d1 = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                let d2 = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                return d1 > d2 // newest first
            }

        guard files.count > self.config.maxArchivedFiles else { return }
        for stale in files.dropFirst(self.config.maxArchivedFiles) {
            try fm.removeItem(at: stale)
        }
    }
}
