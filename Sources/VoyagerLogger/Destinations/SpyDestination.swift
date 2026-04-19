//
//  SpyDestination.swift
//  VoyagerLogger
//
//  Created by Gábor Sajó on 2026-04-09.
//

import os

public final class SpyDestination: LogDestination, Sendable {
    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    public struct Entry: Sendable {
        public let level: LogLevel
        public let message: String
        public let meta: LogMetadata
    }

    public var entries: [Entry] {
        self.state.withLock { $0 }
    }

    public func log(
        _ level: LogLevel,
        message: @autoclosure () -> any Sendable,
        info: LogInfo,
        meta: LogMetadata,
        file: String,
        function: String,
        line: Int
    ) {
        let entry = Entry(level: level, message: "\(message())", meta: meta)
        self.state.withLock { $0.append(entry) }
    }

    public func reset() {
        self.state.withLock { $0.removeAll() }
    }

    // MARK: Private

    private let state = OSAllocatedUnfairLock(initialState: [Entry]())
}
