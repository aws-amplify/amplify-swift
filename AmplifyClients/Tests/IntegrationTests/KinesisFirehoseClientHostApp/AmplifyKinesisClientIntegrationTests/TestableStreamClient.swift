//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyRecordCache
import Foundation

/// Thin test-only abstraction over `AmplifyKinesisClient` and `AmplifyFirehoseClient`
/// so shared integration tests can be written once.
///
/// The only API difference between the two clients is that Kinesis requires a
/// `partitionKey` on `record()` while Firehose does not. This protocol normalises
/// that by dropping `partitionKey` — the Kinesis adapter supplies a default internally.
protocol TestableStreamClient {
    @discardableResult
    func record(data: Data, streamName: String) async throws -> RecordData
    @discardableResult
    func flush() async throws -> FlushData
    @discardableResult
    func clearCache() async throws -> ClearCacheData
    func disable() async
    func enable() async
}
