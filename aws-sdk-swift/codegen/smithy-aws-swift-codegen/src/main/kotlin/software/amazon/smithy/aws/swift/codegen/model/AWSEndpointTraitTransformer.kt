/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen.model

import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.traits.EndpointTrait
import software.amazon.smithy.model.transform.ModelTransformer
import software.amazon.smithy.rulesengine.traits.StaticContextParamsTrait
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.model.getTrait

/**
 * This integration is responsible for removing the EndpointTrait from the operation
 * - For S3 Control, if hostPrefix is {AccountId}., then remove the Endpoint Trait because it is already handled
 *      within the EndpointResolver
 */
class AWSEndpointTraitTransformer : SwiftIntegration {
    override fun preprocessModel(model: Model, settings: SwiftSettings): Model {
        return when (settings.service.namespace) {
            "com.amazonaws.s3control" -> {
                ModelTransformer.create().mapShapes(model) { shape ->
                    when (shape) {
                        is OperationShape -> {
                            val shapeBuilder = shape.toBuilder()
                            shape.getTrait<StaticContextParamsTrait>()?.let { staticContextParamsTrait ->
                                val requiresAccountId =
                                    staticContextParamsTrait.parameters["RequiresAccountId"]?.value
                                        .toString()
                                        .toBoolean()
                                if (requiresAccountId) {
                                    shape.getTrait<EndpointTrait>()?.let { endpointTrait ->
                                        val hostPrefix = endpointTrait.hostPrefix.toString()
                                        if (hostPrefix == "{AccountId}.") {
                                            shapeBuilder.removeTrait(endpointTrait.toShapeId())
                                        }
                                    }
                                }
                            }

                            shapeBuilder.build()
                        }

                        else -> shape
                    }
                }
            }

            else -> model
        }
    }
}
