//
//  OSLogDestination.swift
//  VoyagerLogger
//
//  Created by Gábor Sajó on 2026-04-09.
//

import OSLog

public struct OSLogDestination: LogDestination {
    // MARK: Lifecycle

    public init(
        subsystem: String,
        category: String,
        minimumLevel: LogLevel = .debug,
        format: LogMessageFormat = .osLogDefault
    ) {
        self.logger = os.Logger(subsystem: subsystem, category: category)
        self.minimumLevel = minimumLevel
        self.format = format
    }

    // MARK: Public

    public let minimumLevel: LogLevel
    public let format: LogMessageFormat

    public func log(
        _ level: LogLevel,
        message: @autoclosure () -> any Sendable,
        info: LogInfo?,
        meta: LogMetadata,
        file: String,
        function: String,
        line: Int
    ) {
        guard level >= self.minimumLevel else { return }
        let formatted = self.format.format(
            level: level,
            message: "\(message())",
            file: file,
            function: function,
            line: line
        )
        switch level {
        case .verbose: self.logger.trace("\(formatted, privacy: .public)")
        case .debug: self.logger.debug("\(formatted, privacy: .public)")
        case .info: self.logger.notice("\(formatted, privacy: .public)")
        case .warning: self.logger.warning("\(formatted, privacy: .public)")
        case .error: self.logger.error("\(formatted, privacy: .public)")
        }
    }

    // MARK: Private

    private let logger: os.Logger
}
