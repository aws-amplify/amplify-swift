import Foundation

public struct AmplifySequence<Element: Sendable>: AsyncSequence {
    public typealias Iterator = AsyncStream<Element>.Iterator
    private var asyncStream: AsyncStream<Element>! = nil
    private var continuation: AsyncStream<Element>.Continuation! = nil

    public init(bufferingPolicy: AsyncStream<Element>.Continuation.BufferingPolicy = .unbounded) {
        asyncStream = AsyncStream<Element>(Element.self, bufferingPolicy: bufferingPolicy) { continuation in
            self.continuation = continuation
        }
    }

    public func makeAsyncIterator() -> Iterator {
        asyncStream.makeAsyncIterator()
    }

    public func send(_ element: Element) {
        continuation.yield(element)
    }

    public func finish() {
        continuation.finish()
    }
}
