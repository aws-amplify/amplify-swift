/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen.model

import software.amazon.smithy.model.Model
import software.amazon.smithy.model.pattern.UriPattern
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.traits.HttpLabelTrait
import software.amazon.smithy.model.traits.HttpTrait
import software.amazon.smithy.model.transform.ModelTransformer
import software.amazon.smithy.rulesengine.traits.ContextParamTrait
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.model.hasTrait

/**
 * This integration is responsible for updating the `@httpLabel` trait to the input shape of an operation
 * - For S3, if the HttpLabel is /{BucketName}{Suffix} then update the trait with /{Suffix} because
 *      the bucket name is already handled within the EndpointResolver
 */
class AWSHttpTraitTransformer : SwiftIntegration {
    override fun preprocessModel(model: Model, settings: SwiftSettings): Model {
        return when (settings.service.namespace) {
            "com.amazonaws.s3" -> {
                ModelTransformer.create().mapShapes(model) { shape ->
                    when (shape) {
                        is OperationShape -> {
                            val shapeBuilder = shape.toBuilder()
                            shape.input.orElse(null)?.let { input ->
                                val inputShape = model.expectShape(input.toShapeId())
                                shape.getTrait<HttpTrait>()?.let { httpTrait ->
                                    val uriPattern = httpTrait.uri.toString()
                                    val httpTraitBuilder = httpTrait.toBuilder()
                                    val members = inputShape.members() ?: emptyList()
                                    members.forEach { member ->
                                        if (member.hasTrait<ContextParamTrait>() &&
                                            member.hasTrait<HttpLabelTrait>() &&
                                            member.memberName == "Bucket" &&
                                            uriPattern.startsWith("/{Bucket}")
                                        ) {
                                            var newPattern = uriPattern.substring("/{Bucket}".length)
                                            if (!newPattern.startsWith("/")) {
                                                newPattern = "/$newPattern"
                                            }
                                            httpTraitBuilder.uri(UriPattern.parse(newPattern))
                                            shapeBuilder.addTrait(httpTraitBuilder.build())
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
