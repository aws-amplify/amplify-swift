//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import AWSClientRuntime
import ClientRuntime
import Foundation

/// Generic RecordClient that coordinates storage and sending of records
package actor RecordClient {
    private let sender: RecordSender
    private let storage: RecordStorage
    private let maxRetries: Int
    private let logger = AmplifyFoundation.AmplifyLogging.logger(for: RecordClient.self)
    private var isFlushing = false

    /// Whether the cache is this client's own (its client was given a cache identifier), so a `.discard`
    /// credentials failure may delete what it holds. The region's shared cache holds every session's records.
    private let ownsCache: Bool

    /// How many flushes in a row failed for credentials and kept their records for a later flush: what the
    /// auto-flush backs off on. A flush that completes (with or without records to send), one whose credentials
    /// failure is a `.discard` (nothing is left waiting for the provider), or one whose send fails for another
    /// reason than credentials or a cancellation, ends the streak, manual or scheduled. A cancelled flush, and one
    /// that fails reading the cache, leave it.
    package private(set) var credentialsFailureStreak = 0

    /// - Parameter ownsCache: See `ownsCache`. `false` by default: the region's shared cache.
    package init(
        sender: RecordSender,
        storage: RecordStorage,
        maxRetries: Int = 3,
        ownsCache: Bool = false
    ) {
        self.sender = sender
        self.storage = storage
        self.maxRetries = maxRetries
        self.ownsCache = ownsCache
    }

    /// Ends the credentials-failure streak: the auto-flush starts again at its own interval.
    package func resetCredentialsFailureStreak() {
        credentialsFailureStreak = 0
    }

    /// Records data to local storage
    package func record(_ input: RecordInput) async throws -> RecordData {
        try await storage.addRecord(input)
        return RecordData()
    }

    /// Flushes all locally stored records
    ///
    /// **A credentials failure** (the sender throws the provider's `CredentialsError`; any other provider error is
    /// a failed send, as before) stops the flush, since every stream would fail the same way, and throws
    /// `RecordCacheError.credentials`. What happens to the records follows the error's `disposition`:
    /// - `.discard`, when the cache is this client's own (`ownsCache`): every record cached when the flush began
    ///   is deleted, in every stream; records added during the flush are kept.
    /// - `.discard`, in the region's shared cache: nothing is deleted at once, since it holds other sessions'
    ///   records too. The records of the request that failed count a retry, exactly as for any failed send, so
    ///   they are still removed after `maxRetries + 1` failed flushes of that request, with no back-off.
    /// - `.retryAfterReauthentication`, `.retryWithBackoff`, `.failLoudly`, and any disposition added later: kept
    ///   for a later flush, with no retry counted, since the failure says nothing about the records. Only these
    ///   count toward `credentialsFailureStreak`.
    ///
    /// A cancelled flush whose send fails applies no disposition and counts no retry: it throws what stopped it.
    /// One whose send succeeds completes as any other flush.
    package func flush() async throws -> FlushData {
        guard !isFlushing else {
            logger.debug("Flush already in progress, skipping")
            return FlushData(recordsFlushed: 0, flushInProgress: true)
        }

        isFlushing = true
        defer { isFlushing = false }

        var totalFlushed = 0
        var lastIdByStream: [String: Int64] = [:]
        // What a `.discard` credentials failure removes: everything cached when this flush began.
        let lastIdAtStart = try await ownsCache ? storage.maxRecordId() : nil

        var recordsByStreamList: [[Record]] = try await storage.getRecordsByStream(afterIdByStream: lastIdByStream)
        while !recordsByStreamList.isEmpty {

            logger.debug("Retrieved \(recordsByStreamList.count) stream(s) with records to flush")

            for records in recordsByStreamList {
                guard !records.isEmpty else { continue }
                let streamName = records[0].streamName
                let recordCount = records.count
                logger.verbose("Flushing \(recordCount) records to stream: \(streamName)")

                // Track the last record ID per stream so subsequent batches start after it
                let maxId = records.map(\.id).max() ?? 0
                lastIdByStream[streamName] = maxId

                do {
                    let response = try await sender.putRecords(streamName: streamName, records: records)

                    totalFlushed += response.successfulIds.count

                    try await withThrowingTaskGroup(of: Void.self) { group in
                        group.addTask { try await self.storage.deleteRecords(ids: response.successfulIds) }
                        group.addTask { try await self.storage.incrementRetryCount(ids: response.retryableIds) }
                        group.addTask { try await self.storage.deleteRecords(ids: response.failedIds) }
                        try await group.waitForAll()
                    }

                    logger.verbose(
                        "Stream \(streamName): \(response.successfulIds.count) succeeded, "
                            + "\(response.retryableIds.count) retryable, \(response.failedIds.count) failed"
                    )
                } catch let error as CredentialsError {
                    throw await credentialsFailure(error, sending: records, cachedUpTo: lastIdAtStart)
                } catch {
                    // A cancelled flush says nothing about the records either: no retry is counted.
                    if Task.isCancelled || error is CancellationError {
                        throw error
                    }
                    credentialsFailureStreak = 0
                    // Increment retry count for retryable records and delete those at the limit
                    await handleFailedRequest(records)

                    // SDK errors are logged but not thrown — one stream shouldn't block others
                    let isSdkError = error is ModeledError || error is AWSServiceError
                    if isSdkError {
                        logger.warn(
                            "SDK error flushing stream \(streamName): \(error.localizedDescription)"
                        )
                    } else {
                        // Network errors, storage errors, and unexpected errors — throw to caller
                        logger.warn(
                            "Error flushing stream \(streamName): \(error.localizedDescription)"
                        )
                        throw error
                    }
                }
            }
            recordsByStreamList = try await storage.getRecordsByStream(afterIdByStream: lastIdByStream)
        }

        credentialsFailureStreak = 0
        return FlushData(recordsFlushed: totalFlushed)
    }

    /// Applies the failure's `disposition` to the records and to the streak (see `flush()`), and returns what the
    /// flush throws. `records` are those of the request the provider failed.
    private func credentialsFailure(
        _ error: CredentialsError,
        sending records: [Record],
        cachedUpTo lastId: Int64?
    ) async -> RecordCacheError {
        let thrown = RecordCacheError.credentials(error.errorDescription, error.recoverySuggestion, error)
        // A cancelled flush says nothing about the records or the provider: nothing is counted or deleted.
        guard !Task.isCancelled else {
            return thrown
        }
        switch error.disposition {
        case .discard:
            // Nothing is left waiting for the provider, so there is nothing to back off for.
            credentialsFailureStreak = 0
            if !ownsCache {
                // The shared cache: as before `CredentialsError` was told apart, so these records still expire.
                await handleFailedRequest(records)
            } else if let lastId {
                do {
                    try await storage.deleteRecords(upTo: lastId)
                    logger.warn("Discarded the records cached before the flush: \(error.errorDescription)")
                } catch {
                    logger.error("Failed to discard the cached records: \(error.localizedDescription)")
                }
            }
        case .retryAfterReauthentication, .retryWithBackoff, .failLoudly:
            credentialsFailureStreak += 1
        @unknown default:
            // As `.retryWithBackoff`: a disposition this version does not know must never cost buffered work.
            credentialsFailureStreak += 1
        }
        return thrown
    }

    private func handleFailedRequest(_ records: [Record]) async {
        let retryable = records.filter { $0.retryCount < maxRetries }
        let expired = records.filter { $0.retryCount >= maxRetries }

        do {
            try await storage.incrementRetryCount(ids: retryable.map(\.id))
            try await storage.deleteRecords(ids: expired.map(\.id))

            if !expired.isEmpty {
                let streamName = records[0].streamName
                logger.warn(
                    "Deleted \(expired.count) records from stream \(streamName) "
                        + "that exceeded retry limit of \(maxRetries) after failed retries"
                )
            }
        } catch {
            logger.error("Failed to update records for failed request: \(error.localizedDescription)")
        }
    }

    /// Clears all cached records
    package func clearCache() async throws -> ClearCacheData {
        let count = try await storage.clearRecords()
        return ClearCacheData(recordsCleared: count)
    }
}
