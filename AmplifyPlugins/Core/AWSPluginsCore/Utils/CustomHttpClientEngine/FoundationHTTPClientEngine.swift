//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import ClientRuntime

struct PlaceholderError: Error {}

extension Foundation.URLRequest {
    init(sdkRequest: ClientRuntime.SdkHttpRequest) throws {
        guard let url = sdkRequest.endpoint.url else { throw PlaceholderError() }
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

    convenience init(httpURLResponse: HTTPURLResponse, data: Data) {
        let headers = Self.headers(from: httpURLResponse.allHeaderFields)
        let body = HttpBody.stream(ByteStream.from(data: data))
        // fix force unwrap
        let statusCode = HttpStatusCode(rawValue: httpURLResponse.statusCode)!
        self.init(headers: headers, body: body, statusCode: statusCode)
    }
}

@_spi(FoundationHTTPClientEngine)
public struct FoundationHTTPClient: HttpClientEngine {
    public func execute(request: ClientRuntime.SdkHttpRequest) async throws -> ClientRuntime.HttpResponse {
        let urlRequest = try URLRequest(sdkRequest: request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        // Quinn says it's ok to do this.
        // Safely Force Downcasting a URLResponse to an HTTPURLResponse -
        // https://developer.apple.com/forums/thread/120099?answerId=372749022#372749022
        let httpURLResponse = response as! HTTPURLResponse

        let httpResponse = HttpResponse(
            httpURLResponse: httpURLResponse,
            data: data
        )

        return httpResponse
    }

    public init() {}

    /// no-op
    func close() async {}
}
