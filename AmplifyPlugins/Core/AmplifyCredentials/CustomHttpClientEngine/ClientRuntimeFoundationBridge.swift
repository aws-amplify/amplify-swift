//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Smithy
import SmithyHTTPAPI

extension Foundation.URLRequest {
    init(from smithyRequest: SmithyHTTPAPI.HTTPRequest) async throws {
        guard let url = smithyRequest.endpoint.url else {
            throw FoundationClientEngineError.invalidRequestURL(smithyRequest: smithyRequest)
        }
        self.init(url: url)
        httpMethod = smithyRequest.method.rawValue

        for header in smithyRequest.headers.headers {
            for value in header.value {
                addValue(value, forHTTPHeaderField: header.name)
            }
        }

        httpBody = try await smithyRequest.body.readData()
    }
}

extension SmithyHTTPAPI.HTTPResponse {
    private static func headers(
        from allHeaderFields: [AnyHashable: Any]
    ) -> SmithyHTTPAPI.Headers {
        var headers = Headers()
        for header in allHeaderFields {
            switch (header.key, header.value) {
            case let (key, value) as (String, String):
                headers.add(name: key, value: value)
            case let (key, values) as (String, [String]):
                headers.add(name: key, values: values)
            default: continue
            }
        }
        return headers
    }

    convenience init(httpURLResponse: HTTPURLResponse, data: Data) throws {
        let headers = Self.headers(from: httpURLResponse.allHeaderFields)
        let body = ByteStream.data(data)

        guard let statusCode = HTTPStatusCode(rawValue: httpURLResponse.statusCode) else {
            // This shouldn't happen, but `HttpStatusCode` only exposes a failable
            // `init`. The alternative here is force unwrapping, but we can't
            // make the decision to crash here on behalf on consuming applications.
            throw FoundationClientEngineError.unexpectedStatusCode(
                statusCode: httpURLResponse.statusCode
            )
        }
        self.init(headers: headers, body: body, statusCode: statusCode)
    }
}
