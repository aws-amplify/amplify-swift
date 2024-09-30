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

class ListEncodeFormURLGeneratorTests {
    @Test
    fun `001 encode different types of lists`() {
        val context = setupTests("awsquery/query-lists.smithy", "aws.protocoltests.query#AwsQuery")
        val contents = getFileContents(context.manifest, "Sources/Example/models/QueryListsInput+Write.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension QueryListsInput {

    static func write(value: QueryListsInput?, to writer: SmithyFormURL.Writer) throws {
        guard let value else { return }
        try writer["ComplexListArg"].writeList(value.complexListArg, memberWritingClosure: QueryProtocolClientTypes.GreetingStruct.write(value:to:), memberNodeInfo: "member", isFlattened: false)
        try writer["FlattenedListArg"].writeList(value.flattenedListArg, memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: "member", isFlattened: true)
        try writer["Hi"].writeList(value.flattenedListArgWithXmlName, memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: "item", isFlattened: true)
        try writer["ListArg"].writeList(value.listArg, memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: "member", isFlattened: false)
        try writer["ListArgWithXmlNameMember"].writeList(value.listArgWithXmlNameMember, memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: "item", isFlattened: false)
        try writer["flatTsList"].writeList(value.flatTsList, memberWritingClosure: SmithyReadWrite.timestampWritingClosure(format: SmithyTimestamps.TimestampFormat.epochSeconds), memberNodeInfo: "member", isFlattened: true)
        try writer["tsList"].writeList(value.tsList, memberWritingClosure: SmithyReadWrite.timestampWritingClosure(format: SmithyTimestamps.TimestampFormat.epochSeconds), memberNodeInfo: "member", isFlattened: false)
        try writer["Action"].write("QueryLists")
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
