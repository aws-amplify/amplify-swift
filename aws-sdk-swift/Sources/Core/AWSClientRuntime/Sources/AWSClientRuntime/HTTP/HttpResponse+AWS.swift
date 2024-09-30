/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import class SmithyHTTPAPI.HTTPResponse
import ClientRuntime

public extension HTTPResponse {

    /// The value of the x-amz-request-id header.
    var requestID: String? {
        return headers.value(for: "x-amz-request-id")
    }

    /// The value of the x-amz-id-2 header.
    var requestID2: String? {
        return headers.value(for: "x-amz-id-2")
    }
}
