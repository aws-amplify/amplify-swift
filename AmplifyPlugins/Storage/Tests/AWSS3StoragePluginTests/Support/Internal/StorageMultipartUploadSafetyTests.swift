//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Regression tests for GitHub issue #4138 — multipart upload crashes in
// StorageMultipartUploadSession. Each test targets one of the three stack
// traces reported on Amplify 2.53.3. On the unfixed code, the tests either
// fail to compile (because they call throwing APIs that weren't throwing yet)
// or reproduce the crash/race. After the fix they pass.

import XCTest

@testable import Amplify
@testable import AWSS3StoragePlugin

final class StorageMultipartUploadSafetyTests: XCTestCase {

    // MARK: - Crash 3: FileSystem.getFileSize on a missing file -------------

    /// Reproduces the `Fatal.require` crash at `FileSystem.getFileSize` when
    /// the source file has been deleted between selection and upload start.
    /// Pre-fix: `getFileSize` is non-throwing and terminates the process.
    /// Post-fix: it throws and this test asserts the throw.
    func testGetFileSize_missingFile_throwsInsteadOfCrashing() throws {
        let fs = FileSystem()
        let missingURL = fs.createTemporaryFileURL()
        XCTAssertFalse(fs.fileExists(atURL: missingURL))
        XCTAssertThrowsError(try fs.getFileSize(fileURL: missingURL))
    }

    /// Reproduces the upload-time pathway: a local upload source whose file
    /// has been deleted should surface a Swift error through `UploadSource.getFile`
    /// (which is already `throws`) rather than crashing the process.
    func testUploadSource_localSource_missingFile_propagatesError() {
        let fs = FileSystem()
        let missingURL = fs.createTemporaryFileURL()
        let source = UploadSource.local(missingURL)
        XCTAssertThrowsError(try source.getFile(fileSystem: fs))
    }

    // MARK: - Crash 2: data race between fail() and handle() ----------------

    /// Stress test that alternates `fail(error:)` and `handle(uploadPartEvent:)`
    /// on the same session across many threads. Pre-fix, `fail(error:)` reads
    /// and mutates `multipartUpload` without acquiring the serial queue, while
    /// `handle(...)` mutates it on the serial queue.
    ///
    /// Reliable reproduction requires Thread Sanitizer:
    ///
    ///     Xcode → Product → Scheme → Edit Scheme → Test → Diagnostics
    ///     → Thread Sanitizer ✓, then run this test.
    ///
    /// Under TSan this test reports a data race on `multipartUpload` between
    /// `fail(error:)` and `handle(...)`, matching the Crash 2 stack
    /// (swift_retain on `StorageMultipartUpload.uploadId.getter`). Without
    /// TSan the race is latent — the test runs to completion and serves as a
    /// functional regression guard (it also occasionally surfaces the race as
    /// an ARC crash under load, but not deterministically on every run).
    ///
    /// Note: `swift test --sanitize=thread` is broken on Xcode 26 / macOS 26
    /// due to TSan dylib code-signing policy. Run from the Xcode UI with the
    /// scheme diagnostic enabled instead.
    func testConcurrentFailAndHandle_doesNotRace() {
        let client = MockMultipartUploadClient()
        // Stop the mock's automatic part completion so the session stays in
        // `.parts` while we hammer it from multiple threads.
        client.shouldFailPartUpload = { _, _ in false }

        let session = StorageMultipartUploadSession(
            client: client,
            bucket: "b",
            key: "k",
            onEvent: { _ in }
        )

        // Advance the session to `.parts` so `multipartUpload` has non-nil
        // associated values (uploadId, uploadFile, parts). This is the state
        // that tears under concurrent access.
        try? client.createMultipartUpload()

        let iterations = 500
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            if i.isMultiple(of: 2) {
                session.fail(error: NSError(domain: "test", code: i))
            } else {
                session.handle(uploadPartEvent: .progressUpdated(
                    partNumber: 1,
                    bytesTransferred: UInt64(i),
                    taskIdentifier: i
                ))
            }
        }
        // Success criteria: no TSan report, no ARC crash. If the test
        // completes without the process being terminated, the race is gone.
    }

    // MARK: - Crash 1: retryPartUpload fatalError("Invalid state") ----------

    /// Reproduces the `fatalError("Invalid state")` at
    /// `StorageMultipartUploadSession.swift:350`. The race: the URLSession
    /// delegate thread is inside `handle(uploadPartEvent: .failed)` → `retryPartUpload`,
    /// which expects `multipartUpload` to be `.parts(...)`. A concurrent
    /// `cancel()` swaps the state to `.aborting` after the sync block
    /// releases, so the `case .parts` check falls through to fatalError.
    ///
    /// This test drives the scenario by cancelling from the mock's
    /// `didStartPartUpload` callback and immediately injecting a `.failed`
    /// part event on a different queue.
    func testConcurrentCancelAndFailedPartEvent_doesNotCrash() {
        let exp = expectation(description: "terminal event")
        exp.assertForOverFulfill = false

        let client = MockMultipartUploadClient()
        let onEvent: AWSS3StorageServiceBehavior.StorageServiceMultiPartUploadEventHandler = { event in
            switch event {
            case .failed, .completed:
                exp.fulfill()
            default:
                break
            }
        }

        let session = StorageMultipartUploadSession(
            client: client,
            bucket: "b",
            key: "k",
            onEvent: onEvent
        )

        // When part 3 starts, race a cancel against an injected failed event.
        weak var weakSession = session
        client.didStartPartUpload = { _, partNumber in
            guard partNumber == 3 else { return }
            DispatchQueue.global(qos: .userInitiated).async {
                weakSession?.cancel()
            }
            DispatchQueue.global(qos: .default).async {
                weakSession?.handle(uploadPartEvent: .failed(
                    partNumber: 3,
                    error: NSError(domain: "t", code: 1)
                ))
            }
        }

        session.startUpload()

        // Pre-fix: process is killed by `fatalError` before this returns.
        // Post-fix: session aborts or completes cleanly and fulfills the exp.
        wait(for: [exp], timeout: 30.0)
    }
}
