//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import ClientRuntime

extension Foundation.URLRequest {
    init(sdkRequest: ClientRuntime.SdkHttpRequest) throws {
        guard let url = sdkRequest.endpoint.url else {
            throw FoundationClientEngineError.invalidRequestURL(sdkRequest: sdkRequest)
        }
        self.init(url: url)
        httpMethod = sdkRequest.method.rawValue

        for header in sdkRequest.headers.headers {
            for value in header.value {
                addValue(value, forHTTPHeaderField: header.name)
            }
        }

        switch sdkRequest.body {
        case .data(let data): httpBody = data
        case .stream(let stream): httpBody = stream.toBytes().getData()
        case .none: break
        }
    }
}

extension ClientRuntime.HttpResponse {
    private static func headers(
        from allHeaderFields: [AnyHashable: Any]
    ) -> ClientRuntime.Headers {
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
        let body = HttpBody.stream(ByteStream.from(data: data))

        guard let statusCode = HttpStatusCode(rawValue: httpURLResponse.statusCode) else {
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
