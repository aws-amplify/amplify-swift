//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import XCTest
import Amplify

/// Tests asserting that Storage Operations dispatch progress updates via various flavors of the API.
///
/// These tests are useful to play around with the different thresholds for progress notifications.
/// You will always receive a completion notification as long as the upload completes, even if you
/// attach the result listener after the upload has completed.
///
/// However, if you attach a **progress** listener to an operation that has already completed,
/// you will not receive a value from that publisher.
/// is no guarantee at what threshold you will receive more granular updates, since this is controlled
/// by the OS.
///
/// On my laptop, on my network, I only get "progress: 1.0" notifications for payloads
/// of ~0-1MB. After ~1 MB, I start getting notified more frequently.
class AWSS3StoragePluginProgressTests: AWSS3StoragePluginTestBase {

    func testUploadProgressViaListener() async {
        let timestamp = String(Date().timeIntervalSince1970)
        let key = "testUploadProgressViaListener-\(timestamp)"

        let resultReceived = expectation(description: "resultReceived")
        let progressReceived = expectation(description: "progressReceived")
        progressReceived.assertForOverFulfill = false
        _ = Amplify.Storage.uploadData(
            key: key,
            data: .testDataOfSize(.bytes(100)),
            progressListener: { progress in
                progressReceived.fulfill()
                print("Progress: \(progress.fractionCompleted)")
            }, resultListener: { result in
                resultReceived.fulfill()
                print("Result received: \(result)")
            }
        )

        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)
        await self.removeTestFile(withKey: key)
    }

    func testUploadProgressViaPublisher() async {
        var cancellables = Set<AnyCancellable>()

        let timestamp = String(Date().timeIntervalSince1970)
        let key = "testUploadProgressViaPublisher-\(timestamp)"

        let completionReceived = expectation(description: "resultReceived")
        let progressReceived = expectation(description: "progressReceived")
        progressReceived.assertForOverFulfill = false
        let uploadOperation = Amplify.Storage.uploadData(
            key: key,
            data: .testDataOfSize(.bytes(100)))

        uploadOperation.resultPublisher
            .sink(receiveCompletion: { completion in
                completionReceived.fulfill()
                print("Completion received: \(completion)")
            }, receiveValue: { _ in })
            .store(in: &cancellables)

        uploadOperation.inProcessPublisher
            .sink { progress in
                progressReceived.fulfill()
                print("Progress: \(progress.fractionCompleted)")
            }
            .store(in: &cancellables)

        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)
        await self.removeTestFile(withKey: key)
    }

    func testPublisherDeliveryAfterUploadCompletes() async {
        var cancellables = Set<AnyCancellable>()

        let timestamp = String(Date().timeIntervalSince1970)
        let key = "testUploadProgressDeliveryAfterCompletion-\(timestamp)"

        // Wait for the upload to complete
        let uploadComplete = expectation(description: "uploadComplete")
        let uploadOperation = Amplify.Storage.uploadData(
            key: key,
            data: .testDataOfSize(.bytes(100)),
            resultListener: { _ in uploadComplete.fulfill() }
        )
        wait(for: [uploadComplete], timeout: TestCommonConstants.networkTimeout)

        // Result publisher should immediately complete, and should deliver a value
        let resultCompletionReceived = expectation(description: "resultCompletionReceived")
        let resultValueReceived = expectation(description: "resultValueReceived")
        uploadOperation.resultPublisher
            .sink(
                receiveCompletion: { _ in resultCompletionReceived.fulfill() },
                receiveValue: { _ in resultValueReceived.fulfill() }
            )
            .store(in: &cancellables)
        await waitForExpectations(timeout: 0.5)

        // Progress listener should immediately complete without delivering a value
        let progressValueReceived = expectation(description: "progressValueReceived")
        progressValueReceived.isInverted = true
        let progressCompletionReceived = expectation(description: "progressCompletionReceived")
        uploadOperation.inProcessPublisher
            .sink(
                receiveCompletion: { _ in progressCompletionReceived.fulfill() },
                receiveValue: { _ in progressValueReceived.fulfill() }
            )
            .store(in: &cancellables)
        await waitForExpectations(timeout: 0.5)
        await self.removeTestFile(withKey: key)
    }

    // MARK: - Utilities

    private func removeTestFile(withKey key: String) async {
        await withCheckedContinuation { continuation in
            _ = Amplify.Storage.remove(key: key) { _ in
                continuation.resume()
            }
        }
    }
}

private extension Data {
    static func testDataOfSize(_ size: Int) -> Data {
        Data(repeating: 0xff, count: size)
    }
}

private extension Int {
    static func bytes(_ size: Int) -> Int { return size }

    static func kilobytes(_ size: Int) -> Int { return size * 1_024 }
    static func kilobytes(_ size: Float) -> Int { return Int(size * 1_024) }

    static func megabytes(_ size: Int) -> Int { return size * 1_024 * 1_024 }
    static func megabytes(_ size: Float) -> Int { return Int(size * 1_024 * 1_024) }

    static func gigabytes(_ size: Int) -> Int { return size * 1_024 * 1_024 * 1_024 }
    static func gigabytes(_ size: Float) -> Int { return Int(size * 1_024 * 1_024 * 1_024) }
}
