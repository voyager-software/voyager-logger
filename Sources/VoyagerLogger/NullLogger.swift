//
//  NullLogger.swift
//  VoyagerLogger
//
//  Created by Gábor Sajó on 2026-04-09.
//

public struct NullLogger: AppLogger {
    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    public func log(level: LogLevel, message: @autoclosure () -> String, file: String, function: String, line: Int) {}
}
