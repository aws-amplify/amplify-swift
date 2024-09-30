/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

package software.amazon.smithy.aws.swift.codegen.swiftintegrations

import software.amazon.smithy.aws.swift.codegen.middleware.AmzSdkInvocationIdMiddleware
import software.amazon.smithy.aws.swift.codegen.middleware.AmzSdkRequestMiddleware
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.middleware.OperationMiddleware

/**
 * Adds middleware which provide amz-sdk-invocation-id and amz-sdk-request headers.
 */
class AmzSdkRetryHeadersIntegration : SwiftIntegration {
    override fun customizeMiddleware(
        ctx: ProtocolGenerator.GenerationContext,
        operationShape: OperationShape,
        operationMiddleware: OperationMiddleware
    ) {
        operationMiddleware.appendMiddleware(operationShape, AmzSdkInvocationIdMiddleware(ctx.model, ctx.symbolProvider))
        operationMiddleware.appendMiddleware(operationShape, AmzSdkRequestMiddleware(ctx.model, ctx.symbolProvider))
    }
}
