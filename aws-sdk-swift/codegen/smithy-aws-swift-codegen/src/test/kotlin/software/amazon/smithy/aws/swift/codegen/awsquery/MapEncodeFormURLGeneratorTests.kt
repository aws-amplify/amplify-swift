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

class MapEncodeFormURLGeneratorTests {

    @Test
    fun `001 encode different types of maps`() {
        val context = setupTests("awsquery/query-maps.smithy", "aws.protocoltests.query#AwsQuery")
        val contents = getFileContents(context.manifest, "Sources/Example/models/QueryMapsInput+Write.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension QueryMapsInput {

    static func write(value: QueryMapsInput?, to writer: SmithyFormURL.Writer) throws {
        guard let value else { return }
        try writer["ComplexMapArg"].writeMap(value.complexMapArg, valueWritingClosure: QueryProtocolClientTypes.GreetingStruct.write(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
        try writer["FlattenedMap"].writeMap(value.flattenedMap, valueWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: true)
        try writer["Hi"].writeMap(value.flattenedMapWithXmlName, valueWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), keyNodeInfo: "K", valueNodeInfo: "V", isFlattened: true)
        try writer["MapArg"].writeMap(value.mapArg, valueWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
        try writer["MapOfLists"].writeMap(value.mapOfLists, valueWritingClosure: SmithyReadWrite.listWritingClosure(memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: "member", isFlattened: false), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
        try writer["MapWithXmlMemberName"].writeMap(value.mapWithXmlMemberName, valueWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), keyNodeInfo: "K", valueNodeInfo: "V", isFlattened: false)
        try writer["Foo"].writeMap(value.renamedMapArg, valueWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
        try writer["Action"].write("QueryMaps")
        try writer["Version"].write("2020-01-08")
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context =
            TestUtils.executeDirectedCodegen(smithyFile, serviceShapeId, AwsQueryTrait.ID)
        val generator = AWSQueryProtocolGenerator()
        generator.generateCodableConformanceForNestedTypes(context.ctx)
        generator.generateSerializers(context.ctx)
        context.ctx.delegator.flushWriters()
        return context
    }
}
