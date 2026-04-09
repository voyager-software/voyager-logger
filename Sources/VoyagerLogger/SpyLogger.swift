//
//  SpyLogger.swift
//  VoyagerLogger
//
//  Created by Gábor Sajó on 2026-04-09.
//

import Foundation

public final class SpyLogger: AppLogger, @unchecked Sendable {
    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    public struct Entry {
        public let level: LogLevel
        public let message: String
    }

    public var entries: [Entry] {
        self.lock.withLock { self._entries }
    }

    public func log(level: LogLevel, message: @autoclosure () -> String, file: String, function: String, line: Int) {
        let entry = Entry(level: level, message: message())
        self.lock.withLock { self._entries.append(entry) }
    }

    public func reset() {
        self.lock.withLock { self._entries.removeAll() }
    }

    // MARK: Private

    private let lock = NSLock()
    private var _entries: [Entry] = []
}
