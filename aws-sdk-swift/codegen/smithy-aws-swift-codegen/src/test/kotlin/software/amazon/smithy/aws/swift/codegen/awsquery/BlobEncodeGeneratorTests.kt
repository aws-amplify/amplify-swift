/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen.awsquery

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.aws.swift.codegen.TestContext
import software.amazon.smithy.aws.swift.codegen.TestUtils.Companion.executeDirectedCodegen
import software.amazon.smithy.aws.swift.codegen.TestUtils.Companion.getFileContents
import software.amazon.smithy.aws.swift.codegen.protocols.awsquery.AWSQueryProtocolGenerator
import software.amazon.smithy.aws.swift.codegen.shouldSyntacticSanityCheck
import software.amazon.smithy.aws.traits.protocols.AwsQueryTrait

class BlobEncodeGeneratorTests {
    @Test
    fun `001 encode blobs`() {
        val context = setupTests("awsquery/query-blobs.smithy", "aws.protocoltests.query#AwsQuery")
        val contents = getFileContents(context.manifest, "Sources/Example/models/BlobInputParamsInput+Write.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension BlobInputParamsInput {

    static func write(value: BlobInputParamsInput?, to writer: SmithyFormURL.Writer) throws {
        guard let value else { return }
        try writer["BlobList"].writeList(value.blobList, memberWritingClosure: SmithyReadWrite.WritingClosures.writeData(value:to:), memberNodeInfo: "member", isFlattened: false)
        try writer["BlobListFlattened"].writeList(value.blobListFlattened, memberWritingClosure: SmithyReadWrite.WritingClosures.writeData(value:to:), memberNodeInfo: "member", isFlattened: true)
        try writer["BlobMap"].writeMap(value.blobMap, valueWritingClosure: SmithyReadWrite.WritingClosures.writeData(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
        try writer["BlobMapFlattened"].writeMap(value.blobMapFlattened, valueWritingClosure: SmithyReadWrite.WritingClosures.writeData(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: true)
        try writer["BlobMember"].write(value.blobMember)
        try writer["Action"].write("BlobInputParams")
        try writer["Version"].write("2020-01-08")
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = executeDirectedCodegen(smithyFile, serviceShapeId, AwsQueryTrait.ID)
        val generator = AWSQueryProtocolGenerator()
        generator.generateCodableConformanceForNestedTypes(context.ctx)
        generator.generateSerializers(context.ctx)
        generator.generateDeserializers(context.ctx)
        context.ctx.delegator.flushWriters()
        return context
    }
}
