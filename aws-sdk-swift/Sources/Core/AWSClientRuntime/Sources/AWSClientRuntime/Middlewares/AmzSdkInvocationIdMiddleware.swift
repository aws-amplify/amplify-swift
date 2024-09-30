//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime
import Smithy
import SmithyHTTPAPI
import struct Foundation.UUID

private let AMZ_SDK_INVOCATION_ID_HEADER = "amz-sdk-invocation-id"

/// Adds the amz-sdk-invocation-id header to requests.
public struct AmzSdkInvocationIdMiddleware<InputType, OperationStackOutput> {
    public var id: String { "AmzSdkInvocationId" }

    // The UUID string used to uniquely identify an API call and all of its subsequent retries.
    private let invocationId = UUID().uuidString.lowercased()

    public init() {}

    private func addHeader(builder: HTTPRequestBuilder) {
        builder.withHeader(name: AMZ_SDK_INVOCATION_ID_HEADER, value: invocationId)
    }
}

extension AmzSdkInvocationIdMiddleware: Interceptor {
    public typealias InputType = InputType
    public typealias OutputType = OperationStackOutput
    public typealias RequestType = HTTPRequest
    public typealias ResponseType = HTTPResponse

    public func modifyBeforeRetryLoop(context: some MutableRequest<InputType, HTTPRequest>) async throws {
        let builder = context.getRequest().toBuilder()
        addHeader(builder: builder)
        context.updateRequest(updated: builder.build())
    }
}
