import Testing
@testable import VoyagerLogger

struct LogMessageFormatTests {
    @Test
    func `osLogDefault matches current layout`() {
        let formatted = LogMessageFormat.osLogDefault.format(
            level: .info,
            message: "hello",
            file: "SampleFile",
            function: "sampleFunction",
            line: 42
        )

        #expect(formatted == "SampleFile.sampleFunction():42 hello")
    }

    @Test
    func `rollingFileDefault includes timestamp and level`() {
        let formatted = LogMessageFormat.rollingFileDefault.format(
            level: .warning,
            message: "disk nearly full",
            file: "Storage",
            function: "checkCapacity",
            line: 8,
            timestamp: "2026-04-10 15:00:00.000"
        )

        #expect(formatted == "[2026-04-10 15:00:00.000] WRN Storage.checkCapacity():8 disk nearly full")
    }

    @Test
    func `supports custom ordering and separators`() {
        let format = LogMessageFormat(
            components: [.message, .level, .callSite],
            separator: " | "
        )

        let formatted = format.format(
            level: .error,
            message: "request failed",
            file: "Network",
            function: "load",
            line: 17
        )

        #expect(formatted == "request failed | ERR | Network.load():17")
    }

    @Test
    func `omits timestamp component when no timestamp is provided`() {
        let format = LogMessageFormat(components: [.timestamp, .message])

        let formatted = format.format(
            level: .debug,
            message: "background refresh",
            file: "RefreshJob",
            function: "run",
            line: 3
        )

        #expect(formatted == "background refresh")
    }
}
