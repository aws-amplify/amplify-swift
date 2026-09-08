//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public typealias WeakAmplifyAsyncThrowingSequenceRef<Element> = WeakRef<AmplifyAsyncThrowingSequence<Element>>

/// - Note: `@unchecked Sendable` for the same reason as ``AmplifyAsyncSequence``: `_parent` and
///   `_isCancelled` are mutable but every access is serialized by `lock`.
public class AmplifyAsyncThrowingSequence<Element: Sendable>: AsyncSequence, Cancellable, @unchecked Sendable {
    public typealias Iterator = AsyncThrowingStream<Element, Error>.Iterator
    private let asyncStream: AsyncThrowingStream<Element, Error>
    private let continuation: AsyncThrowingStream<Element, Error>.Continuation

    /// Guards `_parent` and `_isCancelled`. The stream continuation is already thread-safe.
    private let lock = NSLock()
    private var _parent: Cancellable?
    private var _isCancelled: Bool = false

    /// Externally read-only, exactly as the previous `public private(set)` stored property was.
    public var isCancelled: Bool {
        lock.withLock { _isCancelled }
    }

    public init(
        parent: Cancellable? = nil,
        bufferingPolicy: AsyncThrowingStream<Element, Error>.Continuation.BufferingPolicy = .unbounded
    ) {
        self._parent = parent
        (self.asyncStream, self.continuation) = AsyncThrowingStream.makeStream(of: Element.self, bufferingPolicy: bufferingPolicy)
    }

    public func makeAsyncIterator() -> Iterator {
        asyncStream.makeAsyncIterator()
    }

    public func send(_ element: Element) {
        continuation.yield(element)
    }

    public func fail(_ error: Error) {
        continuation.yield(with: .failure(error))
        continuation.finish()
    }

    public func finish() {
        continuation.finish()
        lock.withLock { _parent = nil }
    }

    public func cancel() {
        // Claim the cancellation under the lock so concurrent callers cannot both observe
        // `false` and then cancel `parent` twice, as the previous check-then-set allowed.
        let claimed: (didClaim: Bool, parent: Cancellable?) = lock.withLock {
            guard !_isCancelled else { return (false, nil) }
            _isCancelled = true
            return (true, _parent)
        }
        guard claimed.didClaim else { return }
        claimed.parent?.cancel()
        finish()
    }

}
