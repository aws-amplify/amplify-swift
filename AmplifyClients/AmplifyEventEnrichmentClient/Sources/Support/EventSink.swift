//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Interface for transporting enriched events to a destination.
///
/// Implement this to pipe events to Kinesis, Firehose, or any custom transport.
public protocol EventSink: Sendable {
    /// Sends an enriched event to the configured destination.
    ///
    /// Must return promptly: the client sends one event at a time, so a slow send delays every event behind it.
    /// Must not call `record()` or `close()` on the client, which wait for this send and would never return.
    func send(_ event: EnrichedEvent) async
}
