//
//  RollingFileDestination.swift
//  VoyagerLogger
//
//  Created by Gábor Sajó on 2026-04-09.
//

import Foundation
import os

public final class RollingFileDestination: LogDestination, @unchecked Sendable {
    // MARK: Lifecycle

    public init(configuration: Configuration) throws {
        self.config = configuration
        try FileManager.default.createDirectory(at: configuration.directory, withIntermediateDirectories: true)
    }

    deinit {
        // No queue dispatch needed: deinit only runs once all references are gone,
        // which means no queued blocks and no callers — exclusive access is guaranteed.
        drainPendingEntries()
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
        self.enqueue(entry)
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

    private struct BufferState: Sendable {
        var pendingEntries: [LogEntry] = []
        var drainScheduled = false
    }

    private let config: Configuration
    private let buffer = OSAllocatedUnfairLock(initialState: BufferState())
    private let writerQueue = DispatchQueue(label: "com.voyager.logger.rolling-file-destination")
    private var fileHandle: FileHandle?
    private var currentFileURL: URL?
    private var currentFileSize: Int = 0
    private var fileOpenedAt: Date = .distantPast
    // writerQueue-confined — only accessed from writerQueue
    private let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return f
    }()

    // writerQueue-confined — only accessed from writerQueue
    private let fileNameFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private func enqueue(_ entry: LogEntry) {
        let shouldScheduleDrain = self.buffer.withLock { state in
            state.pendingEntries.append(entry)
            guard !state.drainScheduled else { return false }
            state.drainScheduled = true
            return true
        }

        guard shouldScheduleDrain else { return }
        self.writerQueue.async {
            self.drainPendingEntries()
        }
    }

    private func drainPendingEntries() {
        while true {
            let batch: [LogEntry] = self.buffer.withLock { state in
                guard !state.pendingEntries.isEmpty else {
                    state.drainScheduled = false
                    return []
                }

                let batch = state.pendingEntries
                state.pendingEntries.removeAll(keepingCapacity: true)
                return batch
            }

            guard !batch.isEmpty else { return }
            for entry in batch {
                self.write(entry)
            }
        }
    }

    private func write(_ entry: LogEntry) {
        let line = config.format.format(
            level: entry.level,
            message: entry.message,
            file: entry.file,
            function: entry.function,
            line: entry.line,
            timestamp: timestampFormatter.string(from: entry.date)
        ) + "\n"

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

        // Open new file, appending a counter if needed to avoid collisions
        let baseName = "\(config.filePrefix)_\(fileNameFormatter.string(from: .now))"
        let url = nextAvailableURL(baseName: baseName)
        try Data().write(to: url)
        self.fileHandle = try FileHandle(forWritingTo: url)
        self.currentFileURL = url
        self.currentFileSize = 0
        self.fileOpenedAt = .now

        // Prune old archives
        try self.pruneArchives()
    }

    private func nextAvailableURL(baseName: String) -> URL {
        let dir = config.directory
        let candidate = dir.appending(component: "\(baseName).log")
        guard FileManager.default.fileExists(atPath: candidate.path) else { return candidate }

        var counter = 1
        while true {
            let numbered = dir.appending(component: "\(baseName)_\(counter).log")
            if !FileManager.default.fileExists(atPath: numbered.path) { return numbered }
            counter += 1
        }
    }

    private func pruneArchives() throws {
        let fm = FileManager.default
        let files = try fm.logFiles(in: self.config.directory)

        let archives = files.filter { $0 != self.currentFileURL }
        guard archives.count > self.config.maxArchivedFiles else { return }
        for stale in archives.dropFirst(self.config.maxArchivedFiles) {
            try fm.removeItem(at: stale)
        }
    }

}
