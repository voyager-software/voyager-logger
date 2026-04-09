//
//  OSLogDestination.swift
//  VoyagerLogger
//
//  Created by Gábor Sajó on 2026-04-09.
//

import OSLog

public struct OSLogDestination: AppLogger {
    // MARK: Lifecycle

    public init(subsystem: String, category: String, minimumLevel: LogLevel = .debug) {
        self.logger = os.Logger(subsystem: subsystem, category: category)
        self.minimumLevel = minimumLevel
    }

    // MARK: Public

    public let minimumLevel: LogLevel

    public func log(level: LogLevel, message: @autoclosure () -> String, file: String, function: String, line: Int) {
        guard level >= self.minimumLevel else { return }
        let formatted = "[\(file.fileBaseName):\(line)] \(function): \(message())"
        switch level {
        case .verbose: self.logger.trace("\(formatted, privacy: .public)")
        case .debug: self.logger.debug("\(formatted, privacy: .public)")
        case .info: self.logger.info("\(formatted, privacy: .public)")
        case .warning: self.logger.warning("\(formatted, privacy: .public)")
        case .error: self.logger.error("\(formatted, privacy: .public)")
        }
    }

    // MARK: Private

    private let logger: os.Logger
}
