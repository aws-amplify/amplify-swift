/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.aws.swift.codegen.middleware.OperationEndpointResolverMiddleware
import software.amazon.smithy.aws.swift.codegen.protocols.restjson.AWSRestJson1ProtocolGenerator
import software.amazon.smithy.aws.swift.codegen.swiftmodules.AWSClientRuntimeTypes
import software.amazon.smithy.aws.traits.protocols.RestJson1Trait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.core.GenerationContext
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class OperationEndpointResolverMiddlewareTests {
    @Test
    fun `test endpoint middleware init`() {
        val writer = SwiftWriter("smithy.example")
        val context = setupTests("endpoints.smithy", "smithy.example#ExampleService")
        val operation = context.ctx.model.operationShapes.toList().first { it.id.name == "GetThing" }
        val middleware = OperationEndpointResolverMiddleware(context.ctx, AWSClientRuntimeTypes.Core.EndpointResolverMiddleware)
        middleware.render(context.ctx, writer, operation, "operationStack")
        var contents = writer.toString()
        val expected = """
// OperationContextParam - JMESPath expression: "bar.objects[].content"
let bar = input.bar
let objects = bar?.objects
let projection: [Swift.String]? = objects?.compactMap { original in
    let content = original.content
    return content
}
// OperationContextParam - JMESPath expression: "keys(bar.mapping)"
let bar2 = input.bar
let mapping = bar2?.mapping
let keys = mapping?.keys.map { String(${'$'}0) }
guard let region = config.region else {
    throw Smithy.ClientError.unknownError("Missing required parameter: region")
}
// OperationContextParam - JMESPath expression: "bar.subfield.subfield2"
let bar3 = input.bar
let subfield = bar3?.subfield
let subfield2 = subfield?.subfield2
// OperationContextParam - JMESPath expression: "bar.objects[*].id"
let bar4 = input.bar
let objects2 = bar4?.objects
let projection2: [Swift.String]? = objects2?.compactMap { original in
    let id = original.id
    return id
}
let endpointParams = EndpointParams(boolBar: true, boolBaz: input.fuzz, boolFoo: config.boolFoo, endpoint: config.endpoint, flattenedArray: projection, keysFunctionArray: keys, region: region, stringArrayBar: ["five", "six", "seven"], stringBar: "some value", stringBaz: input.buzz, stringFoo: config.stringFoo, subfield: subfield2, wildcardProjectionArray: projection2)
builder.applyEndpoint(AWSClientRuntime.EndpointResolverMiddleware<GetThingOutput, EndpointParams>(endpointResolverBlock: { [config] in try config.endpointResolver.resolve(params: ${'$'}0) }, endpointParams: endpointParams))
"""
        contents.shouldContainOnlyOnce(expected)
    }
}

private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
    val context = TestUtils.executeDirectedCodegen(smithyFile, serviceShapeId, RestJson1Trait.ID)
    val presigner = PresignerGenerator()
    val generator = AWSRestJson1ProtocolGenerator()
    val codegenContext = GenerationContext(context.ctx.model, context.ctx.symbolProvider, context.ctx.settings, context.manifest, generator)
    val protocolGenerationContext = ProtocolGenerator.GenerationContext(context.ctx.settings, context.ctx.model, context.ctx.service, context.ctx.symbolProvider, listOf(), RestJson1Trait.ID, context.ctx.delegator)
    codegenContext.protocolGenerator?.initializeMiddleware(context.ctx)
    presigner.writeAdditionalFiles(codegenContext, protocolGenerationContext, context.ctx.delegator)
    context.ctx.delegator.flushWriters()
    return context
}
