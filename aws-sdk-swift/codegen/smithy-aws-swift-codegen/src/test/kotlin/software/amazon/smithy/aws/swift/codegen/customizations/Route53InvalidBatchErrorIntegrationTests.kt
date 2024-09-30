package software.amazon.smithy.aws.swift.codegen.customizations

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Disabled
import org.junit.jupiter.api.Test
import software.amazon.smithy.aws.swift.codegen.TestContext
import software.amazon.smithy.aws.swift.codegen.TestUtils
import software.amazon.smithy.aws.swift.codegen.shouldSyntacticSanityCheck
import software.amazon.smithy.aws.traits.protocols.RestXmlTrait

class Route53InvalidBatchErrorIntegrationTests {

    @Disabled
    fun `001 test additional structs and extensions are generated`() {
        val context = setupTests("route53-invalidbatch.smithy", "com.amazonaws.route53#Route53")
        val contents = TestUtils.getFileContents(context.manifest, "/Example/models/ChangeResourceRecordSetsOutputError+Customization.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 test ChangeResourceRecordSetsOutputError+HttpResponseErrorBinding is customized`() {
        val context = setupTests("route53-invalidbatch.smithy", "com.amazonaws.route53#Route53")
        val contents = TestUtils.getFileContents(context.manifest, "Sources/Example/models/ChangeResourceRecordSetsOutputError+HttpResponseErrorBinding.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
enum ChangeResourceRecordSetsOutputError {

    static func httpError(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> Swift.Error {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let baseError = try AWSClientRuntime.RestXMLError(httpResponse: httpResponse, responseReader: responseReader, noErrorWrapping: false)
        if let error = baseError.customError() { return error }
        switch baseError.code {
            case "InvalidChangeBatch": return try InvalidChangeBatch.makeError(baseError: baseError)
            default: return try AWSClientRuntime.UnknownAWSHTTPServiceError.makeError(baseError: baseError)
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestUtils.executeDirectedCodegen(smithyFile, serviceShapeId, RestXmlTrait.ID)
        return context
    }
}
