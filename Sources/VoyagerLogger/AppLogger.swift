//
//  AppLogger.swift
//  VoyagerLogger
//
//  Created by Gábor Sajó on 2026-04-09.
//

public protocol AppLogger: Sendable {
    func log(
        level: LogLevel,
        message: @autoclosure () -> String,
        file: String,
        function: String,
        line: Int
    )
}

public extension AppLogger {
    func verbose(_ msg: @autoclosure () -> String, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(level: .verbose, message: msg(), file: file, function: function, line: line)
    }

    func debug(_ msg: @autoclosure () -> String, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(level: .debug, message: msg(), file: file, function: function, line: line)
    }

    func info(_ msg: @autoclosure () -> String, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(level: .info, message: msg(), file: file, function: function, line: line)
    }

    func warning(_ msg: @autoclosure () -> String, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(level: .warning, message: msg(), file: file, function: function, line: line)
    }

    func error(_ msg: @autoclosure () -> String, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(level: .error, message: msg(), file: file, function: function, line: line)
    }
}
