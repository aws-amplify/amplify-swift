//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A marker protocol to indicate the conforming type can be used as an
/// Environment. Environments provide a way to access dependencies at runtime.
/// - Note: `Sendable` because environments are captured by the actions the state machine runs in
///   detached tasks.
protocol Environment: Sendable { }
