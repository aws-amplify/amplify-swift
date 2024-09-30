/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.intellij.lang.annotations.Language
import org.junit.jupiter.api.Test
import software.amazon.smithy.aws.swift.codegen.protocols.restjson.AWSRestJson1ProtocolGenerator
import software.amazon.smithy.aws.traits.protocols.RestJson1Trait
import software.amazon.smithy.model.node.Node
import software.amazon.smithy.rulesengine.language.EndpointRuleSet
import software.amazon.smithy.swift.codegen.core.GenerationContext
import software.amazon.smithy.swift.codegen.endpoints.EndpointParamsGenerator
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class EndpointParamsGeneratorTests {

    @Test
    fun `test endpoint params init`() {
        val context = setupTests("endpoints.smithy", "smithy.example#ExampleService")
        val endpointParamsGenerator = EndpointParamsGenerator(context.ctx)
        endpointParamsGenerator.render()
        val contents = TestUtils.getFileContents(context.manifest, "Sources/Example/Endpoints.swift")
        val expected = """
public struct EndpointParams {
    public let boolBar: Swift.Bool?
    public let boolBaz: Swift.String?
    public let boolFoo: Swift.Bool
    public let endpoint: Swift.String?
    public let flattenedArray: Swift.Array<Swift.String>?
    public let keysFunctionArray: Swift.Array<Swift.String>?
    public let region: Swift.String
    public let stringArrayBar: Swift.Array<Swift.String>?
    public let stringBar: Swift.String?
    public let stringBaz: Swift.String?
    public let stringFoo: Swift.String?
    public let subfield: Swift.String?
    public let wildcardProjectionArray: Swift.Array<Swift.String>?

    public init(
        boolBar: Swift.Bool? = nil,
        boolBaz: Swift.String? = nil,
        boolFoo: Swift.Bool,
        endpoint: Swift.String? = nil,
        flattenedArray: Swift.Array<Swift.String>? = nil,
        keysFunctionArray: Swift.Array<Swift.String>? = nil,
        region: Swift.String,
        stringArrayBar: Swift.Array<Swift.String>? = nil,
        stringBar: Swift.String? = nil,
        stringBaz: Swift.String? = nil,
        stringFoo: Swift.String? = nil,
        subfield: Swift.String? = nil,
        wildcardProjectionArray: Swift.Array<Swift.String>? = nil
    )
    {
        self.boolBar = boolBar
        self.boolBaz = boolBaz
        self.boolFoo = boolFoo
        self.endpoint = endpoint
        self.flattenedArray = flattenedArray
        self.keysFunctionArray = keysFunctionArray
        self.region = region
        self.stringArrayBar = stringArrayBar
        self.stringBar = stringBar
        self.stringBaz = stringBaz
        self.stringFoo = stringFoo
        self.subfield = subfield
        self.wildcardProjectionArray = wildcardProjectionArray
    }
}
"""
        contents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `test endpoint params extension`() {
        val context = setupTests("endpoints.smithy", "smithy.example#ExampleService")
        val endpointParamsGenerator = EndpointParamsGenerator(context.ctx)
        endpointParamsGenerator.render()
        val contents = TestUtils.getFileContents(context.manifest, "Sources/Example/Endpoints.swift")
        val expected = """
extension EndpointParams: ClientRuntime.EndpointsRequestContextProviding {

    public var context: ClientRuntime.EndpointsRequestContext {
        get throws {
            let context = try ClientRuntime.EndpointsRequestContext()
            try context.add(name: "boolBar", value: self.boolBar)
            try context.add(name: "boolBaz", value: self.boolBaz)
            try context.add(name: "boolFoo", value: self.boolFoo)
            try context.add(name: "endpoint", value: self.endpoint)
            try context.add(name: "flattenedArray", value: self.flattenedArray)
            try context.add(name: "keysFunctionArray", value: self.keysFunctionArray)
            try context.add(name: "region", value: self.region)
            try context.add(name: "stringArrayBar", value: self.stringArrayBar)
            try context.add(name: "stringBar", value: self.stringBar)
            try context.add(name: "stringBaz", value: self.stringBaz)
            try context.add(name: "stringFoo", value: self.stringFoo)
            try context.add(name: "subfield", value: self.subfield)
            try context.add(name: "wildcardProjectionArray", value: self.wildcardProjectionArray)
            return context
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expected)
    }
}

@Language("JSON")
fun String.toRuleset(): EndpointRuleSet {
    return EndpointRuleSet.fromNode(Node.parse(this))
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
