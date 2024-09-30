/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen.awsquery

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.aws.swift.codegen.TestContext
import software.amazon.smithy.aws.swift.codegen.TestUtils
import software.amazon.smithy.aws.swift.codegen.TestUtils.Companion.getFileContents
import software.amazon.smithy.aws.swift.codegen.protocols.awsquery.AWSQueryProtocolGenerator
import software.amazon.smithy.aws.swift.codegen.shouldSyntacticSanityCheck
import software.amazon.smithy.aws.traits.protocols.AwsQueryTrait

class AWSQueryOperationStackTest {
    @Test
    fun `operation stack has required middlewares`() {
        val context = setupTests("awsquery/query-empty-input-output.smithy", "aws.protocoltests.query#AwsQuery")
        val contents = getFileContents(context.manifest, "Sources/Example/QueryProtocolClient.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
        let builder = ClientRuntime.OrchestratorBuilder<NoInputAndOutputInput, NoInputAndOutputOutput, SmithyHTTPAPI.HTTPRequest, SmithyHTTPAPI.HTTPResponse>()
        config.interceptorProviders.forEach { provider in
            builder.interceptors.add(provider.create())
        }
        config.httpInterceptorProviders.forEach { provider in
            builder.interceptors.add(provider.create())
        }
        builder.interceptors.add(ClientRuntime.URLPathMiddleware<NoInputAndOutputInput, NoInputAndOutputOutput>(NoInputAndOutputInput.urlPathProvider(_:)))
        builder.interceptors.add(ClientRuntime.URLHostMiddleware<NoInputAndOutputInput, NoInputAndOutputOutput>())
        builder.interceptors.add(ClientRuntime.ContentLengthMiddleware<NoInputAndOutputInput, NoInputAndOutputOutput>())
        builder.deserialize(ClientRuntime.DeserializeMiddleware<NoInputAndOutputOutput>(NoInputAndOutputOutput.httpOutput(from:), NoInputAndOutputOutputError.httpError(from:)))
        builder.interceptors.add(ClientRuntime.LoggerMiddleware<NoInputAndOutputInput, NoInputAndOutputOutput>(clientLogMode: config.clientLogMode))
        builder.retryStrategy(SmithyRetries.DefaultRetryStrategy(options: config.retryStrategyOptions))
        builder.retryErrorInfoProvider(AWSClientRuntime.AWSRetryErrorInfoProvider.errorInfo(for:))
        builder.applySigner(ClientRuntime.SignerMiddleware<NoInputAndOutputOutput>())
        let endpointParams = EndpointParams()
        builder.applyEndpoint(AWSClientRuntime.EndpointResolverMiddleware<NoInputAndOutputOutput, EndpointParams>(endpointResolverBlock: { [config] in try config.endpointResolver.resolve(params: ${'$'}0) }, endpointParams: endpointParams))
        builder.interceptors.add(AWSClientRuntime.UserAgentMiddleware<NoInputAndOutputInput, NoInputAndOutputOutput>(serviceID: serviceName, version: "1.0.0", config: config))
        builder.serialize(ClientRuntime.BodyMiddleware<NoInputAndOutputInput, NoInputAndOutputOutput, SmithyFormURL.Writer>(rootNodeInfo: "", inputWritingClosure: NoInputAndOutputInput.write(value:to:)))
        builder.interceptors.add(ClientRuntime.ContentTypeMiddleware<NoInputAndOutputInput, NoInputAndOutputOutput>(contentType: "application/x-www-form-urlencoded"))
        builder.selectAuthScheme(ClientRuntime.AuthSchemeMiddleware<NoInputAndOutputOutput>())
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestUtils.executeDirectedCodegen(smithyFile, serviceShapeId, AwsQueryTrait.ID)
        val generator = AWSQueryProtocolGenerator()
        generator.generateCodableConformanceForNestedTypes(context.ctx)
        generator.generateSerializers(context.ctx)
        context.ctx.delegator.flushWriters()
        return context
    }
}
