//
//  SpyDestination.swift
//  VoyagerLogger
//
//  Created by Gábor Sajó on 2026-04-09.
//

import Foundation

public final class SpyDestination: LogDestination, @unchecked Sendable {
    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    public struct Entry {
        public let level: LogLevel
        public let message: String
        public let meta: LogMetadata
    }

    public var entries: [Entry] {
        self.lock.withLock { self._entries }
    }

    public func log(level: LogLevel, message: @autoclosure () -> String, meta: LogMetadata, file: String, function: String, line: Int) {
        let entry = Entry(level: level, message: message(), meta: meta)
        self.lock.withLock { self._entries.append(entry) }
    }

    public func reset() {
        self.lock.withLock { self._entries.removeAll() }
    }

    // MARK: Private

    private let lock = NSLock()
    private var _entries: [Entry] = []
}
