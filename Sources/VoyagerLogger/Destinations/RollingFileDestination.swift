//
//  RollingFileDestination.swift
//  VoyagerLogger
//
//  Created by Gábor Sajó on 2026-04-09.
//

import Foundation

public final class RollingFileDestination: LogDestination, @unchecked Sendable {
    // MARK: Lifecycle

    public init(configuration: Configuration) throws {
        self.config = configuration
        try FileManager.default.createDirectory(at: configuration.directory, withIntermediateDirectories: true)
    }

    deinit {
        try? fileHandle?.close()
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
            minimumLevel: LogLevel = .debug,
            format: LogMessageFormat = .rollingFileDefault
        ) {
            self.directory = directory
            self.filePrefix = filePrefix.isEmpty ? "app" : filePrefix
            self.maxFileSizeBytes = maxFileSizeBytes > 0 ? maxFileSizeBytes : 5 * 1024 * 1024
            self.maxFileAge = maxFileAge > 0 ? maxFileAge : 60 * 60 * 24
            self.maxArchivedFiles = maxArchivedFiles > 0 ? maxArchivedFiles : 1
            self.minimumLevel = minimumLevel
            self.format = format
        }

        // MARK: Public

        public let filePrefix: String
        public let maxFileSizeBytes: Int
        public let maxFileAge: TimeInterval
        public let maxArchivedFiles: Int
        public let minimumLevel: LogLevel
        public let directory: URL
        public let format: LogMessageFormat
    }

    // MARK: - LogDestination

    public func log(_ level: LogLevel, message: @autoclosure () -> any Sendable, meta: LogMetadata, file: String, function: String, line: Int) {
        guard level >= self.config.minimumLevel else { return }
        let entry = LogEntry(level: level, message: "\(message())", file: file, function: function, line: line)
        self.writerQueue.async { self.write(entry) }
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

    private let config: Configuration
    private let writerQueue = DispatchQueue(label: "com.voyager.logger.rolling-file-destination")
    private var fileHandle: FileHandle?
    private var currentFileURL: URL?
    private var currentFileSize: Int = 0
    private var fileOpenedAt: Date = .distantPast

    /// writerQueue-confined — only accessed from writerQueue
    private let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return f
    }()

    /// writerQueue-confined — only accessed from writerQueue
    private let fileNameFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private func write(_ entry: LogEntry) {
        let line = self.config.format.format(
            level: entry.level,
            message: entry.message,
            file: entry.file,
            function: entry.function,
            line: entry.line,
            timestamp: self.timestampFormatter.string(from: entry.date)
        ) + "\n"

        do {
            if self.fileHandle == nil
                || self.currentFileSize >= self.config.maxFileSizeBytes
                || entry.date.timeIntervalSince(self.fileOpenedAt) >= self.config.maxFileAge
            {
                try self.rotate()
            }
            guard let handle = self.fileHandle, let data = line.data(using: .utf8) else { return }
            try handle.write(contentsOf: data)
            self.currentFileSize += data.count
        }
        catch {
            // Intentionally swallow — logging must never crash the app
        }
    }

    private func rotate() throws {
        // Close current handle
        try self.fileHandle?.close()
        self.fileHandle = nil

        let baseName = "\(config.filePrefix)_\(self.fileNameFormatter.string(from: .now))"

        // Single scan: find the latest existing file and the next available name
        let (latest, nextURL) = self.scanFiles(baseName: baseName)

        // Try to reuse the most recent existing file for today if it's still within limits
        if let existing = latest {
            let attrs = try FileManager.default.attributesOfItem(atPath: existing.path)
            let size = (attrs[.size] as? Int) ?? 0
            let created = (attrs[.creationDate] as? Date) ?? .distantPast
            if size < self.config.maxFileSizeBytes,
               Date().timeIntervalSince(created) < self.config.maxFileAge
            {
                self.fileHandle = try FileHandle(forWritingTo: existing)
                try self.fileHandle?.seekToEnd()
                self.currentFileURL = existing
                self.currentFileSize = size
                self.fileOpenedAt = created
                return
            }
        }

        // Create new file
        try Data().write(to: nextURL)
        self.fileHandle = try FileHandle(forWritingTo: nextURL)
        self.currentFileURL = nextURL
        self.currentFileSize = 0
        self.fileOpenedAt = .now

        // Prune old archives
        try self.pruneArchives()
    }

    /// Returns (latestExisting, nextAvailable) in a single pass over the filesystem.
    private func scanFiles(baseName: String) -> (latest: URL?, next: URL) {
        let dir = self.config.directory
        let fm = FileManager.default
        let base = dir.appending(component: "\(baseName).log")

        guard fm.fileExists(atPath: base.path) else {
            return (nil, base)
        }

        var latest = base
        var counter = 1
        while true {
            let numbered = dir.appending(component: "\(baseName)_\(counter).log")
            guard fm.fileExists(atPath: numbered.path) else {
                return (latest, numbered)
            }
            latest = numbered
            counter += 1
        }
    }

    private func pruneArchives() throws {
        let fm = FileManager.default
        let files = try fm.logFiles(in: self.config.directory)

        let archives = files.filter { $0 != self.currentFileURL }
        guard archives.count > self.config.maxArchivedFiles else { return }
        for stale in archives.dropLast(self.config.maxArchivedFiles) {
            try fm.removeItem(at: stale)
        }
    }
}
