package software.amazon.smithy.aws.swift.codegen.customization

import software.amazon.smithy.aws.swift.codegen.model.traits.Presignable
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.transform.ModelTransformer
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.model.expectShape

internal val DEFAULT_PRESIGNABLE_OPERATIONS: Map<String, Set<String>> = mapOf(
    "com.amazonaws.s3#AmazonS3" to setOf(
        "com.amazonaws.s3#GetObject",
        "com.amazonaws.s3#PutObject",
        "com.amazonaws.s3#UploadPart"
    ),
    "com.amazonaws.sts#AWSSecurityTokenServiceV20110615" to setOf(
        "com.amazonaws.sts#GetCallerIdentity"
    ),
    "com.amazonaws.polly#Parrot_v1" to setOf(
        "com.amazonaws.polly#SynthesizeSpeech"
    )
)

class PresignableModelIntegration(private val presignedOperations: Map<String, Set<String>> = DEFAULT_PRESIGNABLE_OPERATIONS) : SwiftIntegration {
    override fun enabledForService(model: Model, settings: SwiftSettings): Boolean {
        val currentServiceId = model.expectShape<ServiceShape>(settings.service).id.toString()

        return presignedOperations.keys.contains(currentServiceId)
    }

    override fun preprocessModel(model: Model, settings: SwiftSettings): Model {
        val currentServiceId = model.expectShape<ServiceShape>(settings.service).id.toString()
        val presignedOperationIds = presignedOperations[currentServiceId]
            ?: error("Expected operation id for service $currentServiceId, but none found in $presignedOperations")
        val transformer = ModelTransformer.create()

        return transformer.mapShapes(model) { shape ->
            if (presignedOperationIds.contains(shape.id.toString())) {
                shape.asOperationShape().get().toBuilder().addTrait(Presignable()).build()
            } else {
                shape
            }
        }
    }
}
