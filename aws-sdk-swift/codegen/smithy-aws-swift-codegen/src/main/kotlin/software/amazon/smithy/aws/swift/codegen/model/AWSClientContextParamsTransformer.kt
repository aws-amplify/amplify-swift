/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen.model

import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.transform.ModelTransformer
import software.amazon.smithy.rulesengine.language.EndpointRuleSet
import software.amazon.smithy.rulesengine.language.syntax.parameters.ParameterType
import software.amazon.smithy.rulesengine.traits.ClientContextParamDefinition
import software.amazon.smithy.rulesengine.traits.ClientContextParamsTrait
import software.amazon.smithy.rulesengine.traits.EndpointRuleSetTrait
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.model.getTrait

/**
 * Transforms the model to add the ClientContextParamsTrait to the service.
 */
class AWSClientContextParamsTransformer : SwiftIntegration {
    override fun preprocessModel(model: Model, settings: SwiftSettings): Model {
        val transformer = ModelTransformer.create()
        return transformer.mapShapes(model) { shape ->
            when (shape) {
                is ServiceShape -> {
                    val shapeBuilder = shape.toBuilder()
                    var trait = shape.getTrait<ClientContextParamsTrait>()
                    var builder =
                        trait?.toBuilder() as ClientContextParamsTrait.Builder? ?: ClientContextParamsTrait.builder()

                    shape.getTrait<EndpointRuleSetTrait>()?.ruleSet?.let { ruleSet ->
                        val endpointRuleSet = EndpointRuleSet.fromNode(ruleSet)
                        endpointRuleSet.parameters.toList().filter {
                            it.builtIn?.orElse(null)?.let { builtIn ->
                                builtIn.split("::").size == 3
                            } ?: false
                        }.map {
                            val definition = ClientContextParamDefinition.builder().type(it.type.toShapeType())
                                .documentation(it.documentation.orElse(null))
                            it.name.toString() to definition.build()
                        }.forEach {
                            builder.putParameter(it.first, it.second)
                        }
                    }

                    shapeBuilder.addTrait(builder.build())
                    shapeBuilder.build()
                }

                else -> shape
            }
        }
    }
}

fun ParameterType.toShapeType(): ShapeType? {
    return when (this) {
        ParameterType.STRING -> ShapeType.STRING
        ParameterType.BOOLEAN -> ShapeType.BOOLEAN
        ParameterType.STRING_ARRAY -> ShapeType.LIST
    }
}
