//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context
import ClientRuntime
import SmithyHTTPAPI

public struct UserAgentMiddleware<OperationStackInput, OperationStackOutput> {
    public let id: String = "UserAgentHeader"

    private let X_AMZ_USER_AGENT: String = "x-amz-user-agent"
    private let USER_AGENT: String = "User-Agent"

    let serviceID: String
    let version: String
    let config: DefaultClientConfiguration & AWSDefaultClientConfiguration

    public init(
        serviceID: String,
        version: String,
        config: DefaultClientConfiguration & AWSDefaultClientConfiguration
    ) {
        self.serviceID = serviceID
        self.version = version
        self.config = config
    }
}

extension UserAgentMiddleware: Interceptor {
    public typealias InputType = OperationStackInput
    public typealias OutputType = OperationStackOutput
    public typealias RequestType = HTTPRequest
    public typealias ResponseType = HTTPResponse

    public func modifyBeforeTransmit(context: some MutableRequest<Self.InputType, HTTPRequest>) async throws {
        let awsUserAgentString = AWSUserAgentMetadata.fromConfigAndContext(
            serviceID: serviceID,
            version: version,
            config: UserAgentValuesFromConfig(config: config),
            context: context.getAttributes()
        ).userAgent
        let builder = context.getRequest().toBuilder()
        builder.withHeader(name: USER_AGENT, value: awsUserAgentString)
        context.updateRequest(updated: builder.build())
    }
}
