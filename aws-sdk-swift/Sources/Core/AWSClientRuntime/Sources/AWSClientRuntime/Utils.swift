//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct AwsCommonRuntimeKit.CommonRuntimeKit

public enum Utils {

    /// Sets up CRT-related shared resources such as the global allocator, event loops, etc.
    ///
    /// Calls to CRT functions may crash the SDK if `CommonRuntimeKit.initialize()` is not called first.
    ///
    /// This function may safely be called multiple times.
    public static func setupCRT() { CommonRuntimeKit.initialize() }
}
