/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen.protocols.awsquery

import software.amazon.smithy.aws.swift.codegen.AWSHTTPProtocolCustomizations
import software.amazon.smithy.aws.swift.codegen.swiftmodules.AWSClientRuntimeTypes
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.protocoltests.traits.HttpRequestTestCase
import software.amazon.smithy.swift.codegen.SwiftWriter

class AWSQueryCustomizations : AWSHTTPProtocolCustomizations() {

    override fun customRenderBodyComparison(test: HttpRequestTestCase): ((SwiftWriter, HttpRequestTestCase, Symbol, Shape, String, String) -> Unit)? {
        return this::renderFormURLBodyComparison
    }

    private fun renderFormURLBodyComparison(writer: SwiftWriter, test: HttpRequestTestCase, symbol: Symbol, shape: Shape, expectedData: String, actualData: String) {
        writer.write("self.assertEqualFormURLBody($expectedData, $actualData)")
    }

    override fun alwaysHasHttpBody(): Boolean {
        return true
    }

    override val baseErrorSymbol: Symbol = AWSClientRuntimeTypes.AWSQuery.AWSQueryError

    override val defaultTimestampFormat = TimestampFormatTrait.Format.DATE_TIME
}
