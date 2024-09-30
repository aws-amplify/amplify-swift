/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.aws.swift.codegen

import software.amazon.smithy.aws.swift.codegen.middleware.OperationEndpointResolverMiddleware
import software.amazon.smithy.aws.swift.codegen.middleware.UserAgentMiddleware
import software.amazon.smithy.aws.swift.codegen.swiftmodules.AWSClientRuntimeTypes
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.rulesengine.language.EndpointRuleSet
import software.amazon.smithy.rulesengine.traits.EndpointRuleSetTrait
import software.amazon.smithy.rulesengine.traits.EndpointTestsTrait
import software.amazon.smithy.swift.codegen.integration.HTTPBindingProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.HTTPProtocolCustomizable
import software.amazon.smithy.swift.codegen.integration.HttpProtocolTestGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolUnitTestErrorGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolUnitTestRequestGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolUnitTestResponseGenerator
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.testModuleName

abstract class AWSHTTPBindingProtocolGenerator(
    customizations: HTTPProtocolCustomizable,
) : HTTPBindingProtocolGenerator(customizations) {

    override var serviceErrorProtocolSymbol: Symbol = AWSClientRuntimeTypes.Core.AWSServiceError

    override val retryErrorInfoProviderSymbol: Symbol
        get() = AWSClientRuntimeTypes.Core.AWSRetryErrorInfoProvider

    override val httpProtocolClientGeneratorFactory = AWSHttpProtocolClientGeneratorFactory()

    val requestTestBuilder = HttpProtocolUnitTestRequestGenerator.Builder()
    val responseTestBuilder = HttpProtocolUnitTestResponseGenerator.Builder()
    val errorTestBuilder = HttpProtocolUnitTestErrorGenerator.Builder()
    open val testsToIgnore: Set<String> = setOf()
    open val tagsToIgnore: Set<String> = setOf()

    override val shouldRenderEncodableConformance = false
    override fun generateProtocolUnitTests(ctx: ProtocolGenerator.GenerationContext): Int {
        return HttpProtocolTestGenerator(
            ctx,
            requestTestBuilder,
            responseTestBuilder,
            errorTestBuilder,
            customizations,
            getProtocolHttpBindingResolver(ctx, defaultContentType),
            testsToIgnore,
            tagsToIgnore,
        ).generateProtocolTests() + renderEndpointsTests(ctx)
    }

    fun renderEndpointsTests(ctx: ProtocolGenerator.GenerationContext): Int {
        val ruleSetNode = ctx.service.getTrait<EndpointRuleSetTrait>()?.ruleSet
        val ruleSet = if (ruleSetNode != null) EndpointRuleSet.fromNode(ruleSetNode) else null
        var testCount = 0

        ctx.service.getTrait<EndpointTestsTrait>()?.let { testsTrait ->
            if (testsTrait.testCases?.isEmpty() == true) {
                return 0
            }

            ctx.delegator.useFileWriter("Tests/${ctx.settings.testModuleName}/EndpointResolverTest.swift") { swiftWriter ->
                testCount = + EndpointTestGenerator(testsTrait, ruleSet, ctx).render(swiftWriter)
            }
        }

        return testCount
    }

    override fun addProtocolSpecificMiddleware(ctx: ProtocolGenerator.GenerationContext, operation: OperationShape) {
        operationMiddleware.appendMiddleware(
            operation,
            OperationEndpointResolverMiddleware(ctx, customizations.endpointMiddlewareSymbol)
        )
        operationMiddleware.appendMiddleware(operation, UserAgentMiddleware(ctx.settings))
    }
}
