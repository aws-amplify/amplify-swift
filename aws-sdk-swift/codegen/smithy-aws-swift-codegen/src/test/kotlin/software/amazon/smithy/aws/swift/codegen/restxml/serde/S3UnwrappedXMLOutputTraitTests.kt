package software.amazon.smithy.aws.swift.codegen.restxml.serde

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.aws.swift.codegen.TestContext
import software.amazon.smithy.aws.swift.codegen.TestUtils
import software.amazon.smithy.aws.swift.codegen.TestUtils.Companion.getFileContents
import software.amazon.smithy.aws.swift.codegen.protocols.restxml.RestXMLProtocolGenerator
import software.amazon.smithy.aws.traits.protocols.RestXmlTrait

class S3UnwrappedXMLOutputTraitTests {
    @Test
    fun `001 S3UnwrappedXmlOutputTrait`() {
        val context = setupTests("restxml/serde/s3unwrappedxmloutput.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/Example/models/GetBucketLocationOutput+HttpResponseBinding.swift")

        val expectedContents = """
extension GetBucketLocationOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> GetBucketLocationOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader.unwrap()
        var value = GetBucketLocationOutput()
        value.locationConstraint = try reader["LocationConstraint"].readIfPresent()
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestUtils.executeDirectedCodegen(smithyFile, serviceShapeId, RestXmlTrait.ID)
        val generator = RestXMLProtocolGenerator()
        generator.generateCodableConformanceForNestedTypes(context.ctx)
        generator.generateDeserializers(context.ctx)
        context.ctx.delegator.flushWriters()
        return context
    }
}
