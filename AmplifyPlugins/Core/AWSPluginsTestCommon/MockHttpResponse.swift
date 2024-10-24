//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyHTTPAPI

class MockHttpResponse {
    class var ok: SmithyHTTPAPI.HTTPResponse {
        SmithyHTTPAPI.HTTPResponse(body: .empty, statusCode: .ok)
    }
}
