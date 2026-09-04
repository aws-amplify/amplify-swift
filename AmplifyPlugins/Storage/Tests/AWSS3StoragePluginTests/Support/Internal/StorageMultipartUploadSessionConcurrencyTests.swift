//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSS3StoragePlugin

// The data races these tests target are reliably detected only under Thread Sanitizer:
//   swift test --sanitize=thread --filter StorageMultipartUploadSessionConcurrencyTests
class StorageMultipartUploadSessionConcurrencyTests: XCTestCase {
    enum Failure: Error {
        case mock
    }

    /// Given: A StorageMultipartUploadSession with parts in progress
    /// When: `fail` is invoked concurrently with reads of the session state
    /// Then: No data race occurs and access does not deadlock
    func testConcurrentFailAndReadDoesNotRace() {
        let client = MockMultipartUploadClient()
        // Keep parts in-progress so the state stays live during the test
        client.shouldStallPartUpload = true

        let session = StorageMultipartUploadSession(
            client: client,
            bucket: "bucket",
            key: "key",
            onEvent: { _ in }
        )
        session.startUpload()

        let iterations = 2_000
        let group = DispatchGroup()

        group.enter()
        DispatchQueue.global().async {
            for _ in 0 ..< iterations {
                session.fail(error: Failure.mock)
            }
            group.leave()
        }

        for _ in 0 ..< 4 {
            group.enter()
            DispatchQueue.global().async {
                for _ in 0 ..< iterations {
                    _ = session.uploadId
                    _ = session.isAborted
                    _ = session.partsCount
                }
                group.leave()
            }
        }

        XCTAssertEqual(group.wait(timeout: .now() + 30), .success, "Concurrent access deadlocked or hung")
    }

    /// Given: A StorageMultipartUploadSession with parts in progress
    /// When: `.failed` part events are handled concurrently, driving retries
    /// Then: The session does not crash and access does not deadlock
    func testConcurrentRetryDoesNotCrash() {
        let client = MockMultipartUploadClient()
        client.shouldStallPartUpload = true

        let session = StorageMultipartUploadSession(
            client: client,
            bucket: "bucket",
            key: "key",
            onEvent: { _ in }
        )
        session.startUpload()

        let partsCount = max(session.partsCount, 1)
        let group = DispatchGroup()

        for _ in 0 ..< 8 {
            group.enter()
            DispatchQueue.global().async {
                for partNumber in 1 ... partsCount {
                    session.handle(uploadPartEvent: .failed(partNumber: partNumber, error: Failure.mock))
                    _ = session.uploadId
                }
                group.leave()
            }
        }

        XCTAssertEqual(group.wait(timeout: .now() + 30), .success, "Concurrent retry deadlocked or hung")
    }
}
