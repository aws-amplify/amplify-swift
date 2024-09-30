/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen.restxml

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.aws.swift.codegen.TestContext
import software.amazon.smithy.aws.swift.codegen.TestUtils.Companion.executeDirectedCodegen
import software.amazon.smithy.aws.swift.codegen.TestUtils.Companion.getFileContents
import software.amazon.smithy.aws.swift.codegen.protocols.restxml.RestXMLProtocolGenerator
import software.amazon.smithy.aws.swift.codegen.shouldSyntacticSanityCheck
import software.amazon.smithy.aws.traits.protocols.RestXmlTrait

class AWSRestXMLHTTPResponseBindingErrorGeneratorTests {

    @Test
    fun `002 GreetingWithErrorsOutputError+HttpResponseBinding`() {
        val context = setupTests("restxml/xml-errors.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/Example/models/GreetingWithErrorsOutputError+HttpResponseErrorBinding.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
enum GreetingWithErrorsOutputError {

    static func httpError(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> Swift.Error {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let baseError = try AWSClientRuntime.RestXMLError(httpResponse: httpResponse, responseReader: responseReader, noErrorWrapping: false)
        if let error = baseError.customError() { return error }
        if let error = try httpServiceError(baseError: baseError) { return error }
        switch baseError.code {
            case "ComplexXMLError": return try ComplexXMLError.makeError(baseError: baseError)
            case "InvalidGreeting": return try InvalidGreeting.makeError(baseError: baseError)
            default: return try AWSClientRuntime.UnknownAWSHTTPServiceError.makeError(baseError: baseError)
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `003 ComplexXMLError+Init`() {
        val context = setupTests("restxml/xml-errors.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/Example/models/ComplexXMLError+Init.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension ComplexXMLError {

    static func makeError(baseError: AWSClientRuntime.RestXMLError) throws -> ComplexXMLError {
        let reader = baseError.errorBodyReader
        let httpResponse = baseError.httpResponse
        var value = ComplexXMLError()
        if let headerHeaderValue = httpResponse.headers.value(for: "X-Header") {
            value.properties.header = headerHeaderValue
        }
        value.properties.nested = try reader["Nested"].readIfPresent(with: RestXmlerrorsClientTypes.ComplexXMLNestedErrorData.read(from:))
        value.properties.topLevel = try reader["TopLevel"].readIfPresent()
        value.httpResponse = baseError.httpResponse
        value.requestID = baseError.requestID
        value.message = baseError.message
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `004 ComplexXMLError extends from AWSHttpServiceError`() {
        val context = setupTests("restxml/xml-errors.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/Sources/Example/models/ComplexXMLError.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
public struct ComplexXMLError: ClientRuntime.ModeledError, AWSClientRuntime.AWSServiceError, ClientRuntime.HTTPError, Swift.Error {

    public struct Properties {
        public internal(set) var header: Swift.String? = nil
        public internal(set) var nested: RestXmlerrorsClientTypes.ComplexXMLNestedErrorData? = nil
        public internal(set) var topLevel: Swift.String? = nil
    }

    public internal(set) var properties = Properties()
    public static var typeName: Swift.String { "ComplexXMLError" }
    public static var fault: ClientRuntime.ErrorFault { .client }
    public static var isRetryable: Swift.Bool { false }
    public static var isThrottling: Swift.Bool { false }
    public internal(set) var httpResponse = SmithyHTTPAPI.HTTPResponse()
    public internal(set) var message: Swift.String?
    public internal(set) var requestID: Swift.String?

    public init(
        header: Swift.String? = nil,
        nested: RestXmlerrorsClientTypes.ComplexXMLNestedErrorData? = nil,
        topLevel: Swift.String? = nil
    )
    {
        self.properties.header = header
        self.properties.nested = nested
        self.properties.topLevel = topLevel
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `005 ComplexXMLErrorNoErrorWrapping Init renders without container`() {
        val context = setupTests("restxml/xml-errors-noerrorwrapping.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/Example/models/ComplexXMLErrorNoErrorWrapping+Init.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension ComplexXMLErrorNoErrorWrapping {

    static func makeError(baseError: AWSClientRuntime.RestXMLError) throws -> ComplexXMLErrorNoErrorWrapping {
        let reader = baseError.errorBodyReader
        let httpResponse = baseError.httpResponse
        var value = ComplexXMLErrorNoErrorWrapping()
        if let headerHeaderValue = httpResponse.headers.value(for: "X-Header") {
            value.properties.header = headerHeaderValue
        }
        value.properties.nested = try reader["Nested"].readIfPresent(with: RestXmlerrorsClientTypes.ComplexXMLNestedErrorData.read(from:))
        value.properties.topLevel = try reader["TopLevel"].readIfPresent()
        value.httpResponse = baseError.httpResponse
        value.requestID = baseError.requestID
        value.message = baseError.message
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `006 RestXml+ServiceErrorHelperMethod AWSHttpServiceError`() {
        val context = setupTests("restxml/xml-errors.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/Example/models/RestXml+HTTPServiceError.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
func httpServiceError(baseError: AWSClientRuntime.RestXMLError) throws -> Swift.Error? {
    switch baseError.code {
        case "ExampleServiceError": return try ExampleServiceError.makeError(baseError: baseError)
        default: return nil
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = executeDirectedCodegen(smithyFile, serviceShapeId, RestXmlTrait.ID)

        RestXMLProtocolGenerator().run {
            generateDeserializers(context.ctx)
            generateCodableConformanceForNestedTypes(context.ctx)
        }

        context.ctx.delegator.flushWriters()
        return context
    }
}
