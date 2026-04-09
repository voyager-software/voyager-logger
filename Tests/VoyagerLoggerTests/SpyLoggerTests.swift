import Testing
@testable import VoyagerLogger

struct SpyLoggerTests {
    @Test
    func `records logged entries`() {
        let spy = SpyLogger()
        spy.info("hello")
        spy.error("boom")

        #expect(spy.entries.count == 2)
        #expect(spy.entries[0].level == .info)
        #expect(spy.entries[0].message == "hello")
        #expect(spy.entries[1].level == .error)
        #expect(spy.entries[1].message == "boom")
    }

    @Test
    func `reset clears all entries`() {
        let spy = SpyLogger()
        spy.info("one")
        spy.warning("two")
        spy.reset()

        #expect(spy.entries.isEmpty)
    }

    @Test
    func `is thread-safe under concurrent access`() async {
        let spy = SpyLogger()
        await withTaskGroup(of: Void.self) { group in
            for i in 0 ..< 100 {
                group.addTask { spy.info("msg \(i)") }
            }
        }
        #expect(spy.entries.count == 100)
    }
}
