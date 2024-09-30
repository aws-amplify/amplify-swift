/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen

import software.amazon.smithy.aws.swift.codegen.swiftmodules.AWSSDKHTTPAuthTypes
import software.amazon.smithy.aws.traits.auth.SigV4ATrait
import software.amazon.smithy.aws.traits.auth.SigV4Trait
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.knowledge.ServiceIndex
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.traits.OptionalAuthTrait
import software.amazon.smithy.swift.codegen.AuthSchemeResolverGenerator
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.expectTrait
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.utils.AuthUtils

open class AWSAuthUtils(
    private val ctx: ProtocolGenerator.GenerationContext
) : AuthUtils(ctx) {
    companion object {
        /**
         * Returns if the SigV4Trait is a auth scheme supported by the service.
         *
         * @param model        model definition
         * @param serviceShape service shape for the API
         * @return if the SigV4 trait is used by the service.
         */
        fun isSupportedAuthentication(model: Model, serviceShape: ServiceShape): Boolean =
            ServiceIndex
                .of(model)
                .getAuthSchemes(serviceShape)
                .values
                .any { it.javaClass == SigV4Trait::class.java }
        /**
         * Get the SigV4Trait auth name to sign request for
         *
         * @param serviceShape service shape for the API
         * @return the service name to use in the credential scope to sign for
         */
        fun signingServiceName(serviceShape: ServiceShape): String {
            val sigv4Trait = serviceShape.expectTrait<SigV4Trait>()
            return sigv4Trait.name
        }

        /**
         * Returns if the SigV4Trait is an auth scheme for the service and operation.
         *
         * @param model     model definition
         * @param service   service shape for the API
         * @param operation operation shape
         * @return if SigV4Trait is an auth scheme for the operation and service.
         */
        fun hasSigV4AuthScheme(model: Model, service: ServiceShape, operation: OperationShape): Boolean {
            val auth = ServiceIndex.of(model).getEffectiveAuthSchemes(service.id, operation.id)
            return auth.containsKey(SigV4Trait.ID) && !operation.hasTrait<OptionalAuthTrait>()
        }
    }

    override fun addAdditionalSchemes(writer: SwiftWriter, authSchemeList: MutableList<String>): List<String> {
        val effectiveAuthSchemes = ServiceIndex(ctx.model).getEffectiveAuthSchemes(ctx.service)

        val sdkId = AuthSchemeResolverGenerator.getSdkId(ctx)
        val servicesUsingSigV4A = arrayOf("S3", "EventBridge", "CloudFrontKeyValueStore")
        var updatedAuthSchemeList = authSchemeList

        if (effectiveAuthSchemes.contains(SigV4Trait.ID)) {
            updatedAuthSchemeList += writer.format("\$N()", AWSSDKHTTPAuthTypes.SigV4AuthScheme)
        }
        if (effectiveAuthSchemes.contains(SigV4ATrait.ID) || servicesUsingSigV4A.contains(sdkId)) {
            updatedAuthSchemeList += writer.format("\$N()", AWSSDKHTTPAuthTypes.SigV4AAuthScheme)
        }

        return updatedAuthSchemeList
    }
}
