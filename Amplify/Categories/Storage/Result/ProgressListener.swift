//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Convenience typealias for a callback invoked with an asynchronous operation's `Progress`
///
/// - Tag: ProgressListener
/// - Note: `@Sendable` because progress is reported from the storage transfer machinery, off the
///   thread that started the operation.
public typealias ProgressListener = @Sendable (Progress) -> Void
