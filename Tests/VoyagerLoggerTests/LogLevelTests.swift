import Testing
@testable import VoyagerLogger

struct LogLevelTests {
    @Test
    func `raw values are ordered from verbose (0) to error (4)`() {
        #expect(LogLevel.verbose.rawValue == 0)
        #expect(LogLevel.debug.rawValue == 1)
        #expect(LogLevel.info.rawValue == 2)
        #expect(LogLevel.warning.rawValue == 3)
        #expect(LogLevel.error.rawValue == 4)
    }

    @Test
    func `Comparable ordering works correctly`() {
        #expect(LogLevel.verbose < .debug)
        #expect(LogLevel.debug < .info)
        #expect(LogLevel.info < .warning)
        #expect(LogLevel.warning < .error)
        #expect(!(LogLevel.error < .verbose))
    }

    @Test(arguments: [
        (LogLevel.verbose, "VERBOSE"),
        (.debug, "DEBUG"),
        (.info, "INFO"),
        (.warning, "WARNING"),
        (.error, "ERROR"),
    ])
    func `labels return uppercase strings`(level: LogLevel, expected: String) {
        #expect(level.label == expected)
    }
}
