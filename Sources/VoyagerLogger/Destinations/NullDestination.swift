//
//  NullDestination.swift
//  VoyagerLogger
//
//  Created by Gábor Sajó on 2026-04-09.
//

public struct NullDestination: LogDestination {
    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    public func log(level: LogLevel, message: @autoclosure () -> any Sendable, meta: LogMetadata, file: String, function: String, line: Int) {}
}
