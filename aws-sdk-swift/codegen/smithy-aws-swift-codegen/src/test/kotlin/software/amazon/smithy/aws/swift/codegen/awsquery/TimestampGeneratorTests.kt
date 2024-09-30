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

class TimestampGeneratorTests {

    @Test
    fun `001 encode timestamps`() {
        val context = setupTests("awsquery/query-timestamp.smithy", "aws.protocoltests.query#AwsQuery")
        val contents = getFileContents(context.manifest, "Sources/Example/models/QueryTimestampsInput+Write.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension QueryTimestampsInput {

    static func write(value: QueryTimestampsInput?, to writer: SmithyFormURL.Writer) throws {
        guard let value else { return }
        try writer["epochMember"].writeTimestamp(value.epochMember, format: SmithyTimestamps.TimestampFormat.epochSeconds)
        try writer["epochTarget"].writeTimestamp(value.epochTarget, format: SmithyTimestamps.TimestampFormat.epochSeconds)
        try writer["normalFormat"].writeTimestamp(value.normalFormat, format: SmithyTimestamps.TimestampFormat.dateTime)
        try writer["Action"].write("QueryTimestamps")
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
