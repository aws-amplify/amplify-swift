//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Convenience typealias
/// - Note: `@Sendable` because callers pass these into tasks and dispatch queues throughout the
///   library.
public typealias BasicClosure = @Sendable () -> Void

public typealias BasicThrowableClosure = () throws -> Void
