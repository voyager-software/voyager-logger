import Testing
@testable import VoyagerLogger

struct NullLoggerTests {
    @Test
    func `does not crash when logging`() {
        let logger = NullLogger()
        logger.verbose("v")
        logger.debug("d")
        logger.info("i")
        logger.warning("w")
        logger.error("e")
    }
}
