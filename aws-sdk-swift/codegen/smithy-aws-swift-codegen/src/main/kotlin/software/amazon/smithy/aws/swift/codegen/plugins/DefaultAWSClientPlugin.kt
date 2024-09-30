/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.plugins

import software.amazon.smithy.aws.swift.codegen.swiftmodules.AWSClientRuntimeTypes
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.Plugin

class DefaultAWSClientPlugin : Plugin {
    override val className: Symbol = AWSClientRuntimeTypes.Core.DefaultAWSClientPlugin

    override val isDefault: Boolean
        get() = true

    override fun customInitialization(writer: SwiftWriter) {
        writer.writeInline("\$N(clientName: self.clientName)", className)
    }
}
