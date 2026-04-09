import Testing
@testable import VoyagerLogger

struct CompositeLoggerTests {
    @Test
    func `fans out to all destinations`() {
        let spy1 = SpyLogger()
        let spy2 = SpyLogger()
        let composite = CompositeLogger([spy1, spy2])

        composite.info("hello")

        #expect(spy1.entries.count == 1)
        #expect(spy1.entries[0].message == "hello")
        #expect(spy2.entries.count == 1)
        #expect(spy2.entries[0].message == "hello")
    }

    @Test
    func `works with empty destinations list`() {
        let composite = CompositeLogger([])
        composite.info("no-op")
    }

    @Test
    func `preserves log level across destinations`() {
        let spy1 = SpyLogger()
        let spy2 = SpyLogger()
        let composite = CompositeLogger([spy1, spy2])

        composite.error("fail")

        #expect(spy1.entries[0].level == .error)
        #expect(spy2.entries[0].level == .error)
    }
}
