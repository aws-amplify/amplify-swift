/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen.restxml

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.aws.swift.codegen.TestContext
import software.amazon.smithy.aws.swift.codegen.TestUtils.Companion.executeDirectedCodegen
import software.amazon.smithy.aws.swift.codegen.TestUtils.Companion.getClientFileContents
import software.amazon.smithy.aws.swift.codegen.protocols.restxml.RestXMLProtocolGenerator
import software.amazon.smithy.aws.swift.codegen.shouldSyntacticSanityCheck
import software.amazon.smithy.aws.traits.protocols.RestXmlTrait

class RestXMLProtocolNoInputNoOutputGeneratorTests {

    @Test
    fun `smoke test for generating request tests`() {
        val context = setupTests("restxml-generator-test.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getClientFileContents("Tests/ExampleTests", "NoInputAndNoOutputRequestTest.swift", context.manifest)
        contents.shouldSyntacticSanityCheck()

        val expectedContents =
            """
            class NoInputAndNoOutputRequestTest: HttpRequestTestBase {
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = executeDirectedCodegen(smithyFile, serviceShapeId, RestXmlTrait.ID)

        val generator = RestXMLProtocolGenerator()
        generator.generateProtocolUnitTests(context.ctx)
        context.ctx.delegator.flushWriters()
        return context
    }
}
