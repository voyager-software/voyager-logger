//
//  AppLogger.swift
//  VoyagerLogger
//
//  Created by Gábor Sajó on 2026-04-09.
//

public struct AppLogger: LogDestination {
    // MARK: Lifecycle

    public init(_ destinations: [any LogDestination]) {
        self.destinations = destinations
    }

    // MARK: Public

    public func log(level: LogLevel, message: @autoclosure () -> any Sendable, meta: LogMetadata, file: String, function: String, line: Int) {
        let msg = "\(message())" // evaluate once, fan out
        for dest in self.destinations {
            dest.log(level: level, message: msg, meta: meta, file: file, function: function, line: line)
        }
    }

    // MARK: Private

    private let destinations: [any LogDestination]
}
