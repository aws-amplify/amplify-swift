//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A thread-safe FIFO queue
final class SynchronizedQueue<Element> {
    private let concurrencyQueue = DispatchQueue(label: "com.amazonaws.SynchronizedQueue",
                                                 qos: .default,
                                                 attributes: .concurrent)

    private var elements = [Element]()

    var count: Int {
        return concurrencyQueue.sync {
            elements.count
        }
    }

    var isEmpty: Bool {
        return concurrencyQueue.sync {
            elements.isEmpty
        }
    }

    func add(_ element: Element) {
        concurrencyQueue.async(flags: .barrier) {
            self.elements.append(element)
        }
    }

    func next() -> Element? {
        var nextElement: Element?
        let semaphore = DispatchSemaphore(value: 0)
        concurrencyQueue.async(flags: .barrier) {
            nextElement = !self.elements.isEmpty ? self.elements.removeFirst() : nil
            semaphore.signal()
        }

        semaphore.wait()
        return nextElement
    }

}
