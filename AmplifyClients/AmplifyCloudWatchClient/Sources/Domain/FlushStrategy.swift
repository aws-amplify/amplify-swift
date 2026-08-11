//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Strategy for flushing cached log events to CloudWatch.
@_spi(AmplifyExperimental)
public enum FlushStrategy: Sendable {
    /// Automatically flush at a regular interval. Default is 60 seconds.
    case interval(TimeInterval = 60)
}
