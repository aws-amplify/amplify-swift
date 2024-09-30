// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import class Smithy.Context
import ClientRuntime
import SmithyHTTPAPI

public struct XAmzTargetMiddleware<OperationStackInput, OperationStackOutput> {
    public let id: String = "XAmzTargetHeader"

    let xAmzTarget: String

    public init(xAmzTarget: String) {
        self.xAmzTarget = xAmzTarget
    }

    private func addHeader(builder: HTTPRequestBuilder) {
        builder.withHeader(name: "X-Amz-Target", value: xAmzTarget)
    }
}

extension XAmzTargetMiddleware: Interceptor {
    public typealias InputType = OperationStackInput
    public typealias OutputType = OperationStackOutput
    public typealias RequestType = HTTPRequest
    public typealias ResponseType = HTTPResponse

    public func modifyBeforeRetryLoop(context: some MutableRequest<Self.InputType, Self.RequestType>) async throws {
        let builder = context.getRequest().toBuilder()
        addHeader(builder: builder)
        context.updateRequest(updated: builder.build())
    }
}
