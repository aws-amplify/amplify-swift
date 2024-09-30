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

class QueryIdempotencyTokenAutoFillGeneratorTests {

    @Test
    fun `001 hardcodes action and version into input type`() {
        val context = setupTests("awsquery/query-idempotency-token.smithy", "aws.protocoltests.query#AwsQuery")
        val contents = getFileContents(context.manifest, "Sources/Example/models/QueryIdempotencyTokenAutoFillInput+Write.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension QueryIdempotencyTokenAutoFillInput {

    static func write(value: QueryIdempotencyTokenAutoFillInput?, to writer: SmithyFormURL.Writer) throws {
        guard let value else { return }
        try writer["token"].write(value.token)
        try writer["Action"].write("QueryIdempotencyTokenAutoFill")
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
