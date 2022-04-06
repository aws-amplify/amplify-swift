//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime

class MockHttpResponse {
    class var ok: HttpResponse {
        HttpResponse(body: .none, statusCode: .ok)
    }
}
