import Foundation
import XCTest

public enum AsyncTesting {

    public static func expectation(description: String,
                                   isInverted: Bool = false,
                                   expectedFulfillmentCount: Int = 1) -> AsyncExpectation {
        AsyncExpectation(description: description,
                         isInverted: isInverted,
                         expectedFulfillmentCount: expectedFulfillmentCount)
    }

    @MainActor
    public static func waitForExpectations(_ expectations: [AsyncExpectation],
                                           timeout: Double = 1.0,
                                           file: StaticString = #filePath,
                                           line: UInt = #line) async {
        guard !expectations.isEmpty else { return }

        // check if all expectations are already satisfied and skip sleeping
        var count = 0
        for exp in expectations {
            if await exp.isFulfilled {
                count += 1
            }
        }
        if count == expectations.count {
            return
        }

        let timeout = Task {
            try await Task.sleep(seconds: timeout)
            for exp in expectations {
                await exp.timeOut(file: file, line: line)
            }
        }

        await waitUsingTaskGroup(expectations)

        timeout.cancel()
    }

    private static func waitUsingTaskGroup(_ expectations: [AsyncExpectation]) async {
        await withTaskGroup(of: Void.self) { group in
            for exp in expectations {
                group.addTask {
                    try? await exp.wait()
                }
            }
        }
    }

}
