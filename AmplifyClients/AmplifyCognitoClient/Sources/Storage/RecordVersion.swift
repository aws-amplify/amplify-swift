//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// What a guarded write expects to find: the commit token a reader hands back to the commit guard.
///
/// `nil` (no version) means "I read no item", and the write is then add-if-absent. A version of one form
/// never matches a record stored in the other: a writer holding one has a stale view of the record.
enum RecordVersion: Equatable, Sendable {
    /// A named session's envelope, at this generation (`SessionRecordEnvelope.generation`).
    case generation(UInt64)
    /// The stored bytes as read, for a record with no generation of its own: `.default`'s, the Auth plugin's
    /// record (`SessionRecordStore+DefaultSession.swift`).
    case storedBytes(Data)
}

/// A session record as read, with the version a guarded write over it must expect.
///
/// `version` is `nil` only for a row with no stored item behind it: `.default`'s signed-out row read from its
/// sidecar alone, with no Auth plugin record, which a write over expects to find absent.
struct VersionedSessionRecord: Equatable, Sendable {
    let record: SessionRecord
    let version: RecordVersion?

    init(record: SessionRecord, version: RecordVersion?) {
        self.record = record
        self.version = version
    }

    /// A named session's envelope, versioned by its generation.
    init(_ envelope: SessionRecordEnvelope) {
        self.init(record: envelope.record, version: .generation(envelope.generation))
    }
}
