/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen

import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.HTTPProtocolCustomizable
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.HttpProtocolClientGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolClientGeneratorFactory
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.middleware.OperationMiddleware

class AWSHttpProtocolClientGeneratorFactory : HttpProtocolClientGeneratorFactory {
    override fun createHttpProtocolClientGenerator(
        ctx: ProtocolGenerator.GenerationContext,
        httpBindingResolver: HttpBindingResolver,
        writer: SwiftWriter,
        serviceName: String,
        defaultContentType: String,
        httpProtocolCustomizable: HTTPProtocolCustomizable,
        operationMiddleware: OperationMiddleware
    ): HttpProtocolClientGenerator {
        val config = AWSServiceConfig(writer, ctx)
        return HttpProtocolClientGenerator(ctx, writer, config, httpBindingResolver, defaultContentType, httpProtocolCustomizable, operationMiddleware)
    }
}
