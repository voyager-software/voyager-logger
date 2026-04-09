import Testing
@testable import VoyagerLogger

struct OSLogDestinationTests {
    @Test
    func `respects minimum level filter`() {
        let dest = OSLogDestination(subsystem: "test", category: "test", minimumLevel: .warning)
        #expect(dest.minimumLevel == .warning)
    }

    @Test
    func `logs all levels to os.Logger`() {
        let dest = OSLogDestination(
            subsystem: "com.voyager.logger.tests",
            category: "OSLogDestinationTests",
            minimumLevel: .verbose
        )
        dest.verbose("verbose message from test")
        dest.debug("debug message from test")
        dest.info("info message from test")
        dest.warning("warning message from test")
        dest.error("error message from test")
    }

    @Test
    func `skips messages below minimum level`() {
        let dest = OSLogDestination(
            subsystem: "com.voyager.logger.tests",
            category: "OSLogDestinationTests",
            minimumLevel: .warning
        )
        // These should NOT appear in the console
        dest.verbose("SHOULD NOT APPEAR - verbose")
        dest.debug("SHOULD NOT APPEAR - debug")
        dest.info("SHOULD NOT APPEAR - info")
        // These SHOULD appear in the console
        dest.warning("warning SHOULD appear")
        dest.error("error SHOULD appear")
    }
}
