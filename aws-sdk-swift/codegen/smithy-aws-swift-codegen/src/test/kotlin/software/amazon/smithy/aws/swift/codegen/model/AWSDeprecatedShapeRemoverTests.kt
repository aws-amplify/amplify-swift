package software.amazon.smithy.aws.swift.codegen.model

import io.kotest.matchers.string.shouldContainOnlyOnce
import io.kotest.matchers.string.shouldNotContain
import org.junit.jupiter.api.Test
import software.amazon.smithy.aws.swift.codegen.TestContext
import software.amazon.smithy.aws.swift.codegen.TestUtils
import software.amazon.smithy.aws.swift.codegen.shouldSyntacticSanityCheck
import software.amazon.smithy.aws.traits.protocols.RestJson1Trait

class AWSDeprecatedShapeRemoverTests {
    @Test
    fun `Shape deprecated before the cutoff date based on deprecated trait's since field gets removed`() {
        val context = setupTests("deprecated-shape-removal-test.smithy", "com.test#Example")
        val contents = TestUtils.getModelFileContents("Sources/Example", "OperationWithDeprecatedInputMembersInput.swift", context.manifest)
        contents.shouldSyntacticSanityCheck()
        val removedContent = """
    @available(*, deprecated, message: "API deprecated since 2024-09-01")
    public var deprecatedMemberWithCorrectlyFormedSinceField: Swift.String?
"""
        contents.shouldNotContain(removedContent)
    }

    @Test
    fun `Shape deprecated after the cutoff date remains unremoved`() {
        val context = setupTests("deprecated-shape-removal-test.smithy", "com.test#Example")
        val contents = TestUtils.getModelFileContents("Sources/Example", "OperationWithDeprecatedInputMembersInput.swift", context.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
    @available(*, deprecated, message: "API deprecated since 2024-10-01")
    public var deprecatedMemberWithCorrectlyFormedSinceFieldButDeprecatedAfterCutoff: Swift.String?
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `Shape with deprecated trait that has malformed since field remains unremoved`() {
        val context = setupTests("deprecated-shape-removal-test.smithy", "com.test#Example")
        val contents = TestUtils.getModelFileContents("Sources/Example", "OperationWithDeprecatedInputMembersInput.swift", context.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
    @available(*, deprecated, message: "API deprecated since 4.2.0")
    public var deprecatedMemberWithMalformedSinceField: Swift.String?
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `Shape with deprecated trait missing since field remains unremoved`() {
        val context = setupTests("deprecated-shape-removal-test.smithy", "com.test#Example")
        val contents = TestUtils.getModelFileContents("Sources/Example", "OperationWithDeprecatedInputMembersInput.swift", context.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
    @available(*, deprecated)
    public var deprecatedMemberWithoutSinceField: Swift.String?
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestUtils.executeDirectedCodegen(smithyFile, serviceShapeId, RestJson1Trait.ID)
        context.ctx.delegator.flushWriters()
        return context
    }
}
