package software.amazon.smithy.aws.swift.codegen.customizations

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.aws.swift.codegen.TestContext
import software.amazon.smithy.aws.swift.codegen.TestUtils
import software.amazon.smithy.aws.swift.codegen.protocols.restjson.AWSRestJson1ProtocolGenerator
import software.amazon.smithy.aws.swift.codegen.shouldSyntacticSanityCheck
import software.amazon.smithy.aws.traits.protocols.RestJson1Trait

class FlexibleChecksumMiddlewareTests {

    @Test
    fun `Test that FlexibleChecksumsRequestMiddleware is properly generated`() {
        val context = setupTests("flexible-checksums.smithy", "aws.flex.checks#ChecksumTests")
        val contents = TestUtils.getFileContents(context.manifest, "Sources/Example/ChecksumTestsClient.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
        builder.interceptors.add(AWSClientRuntime.FlexibleChecksumsRequestMiddleware<SomeOperationInput, SomeOperationOutput>(checksumAlgorithm: input.checksumAlgorithm?.rawValue))
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `Test that FlexibleChecksumsResponseMiddleware is properly generated`() {
        val context = setupTests("flexible-checksums.smithy", "aws.flex.checks#ChecksumTests")
        val contents = TestUtils.getFileContents(context.manifest, "Sources/Example/ChecksumTestsClient.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
        builder.interceptors.add(AWSClientRuntime.FlexibleChecksumsResponseMiddleware<SomeOperationInput, SomeOperationOutput>(validationMode: true))
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestUtils.executeDirectedCodegen(smithyFile, serviceShapeId, RestJson1Trait.ID)
        val generator = AWSRestJson1ProtocolGenerator()
        generator.generateProtocolUnitTests(context.ctx)
        context.ctx.delegator.flushWriters()
        return context
    }
}
