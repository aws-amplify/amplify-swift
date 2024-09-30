package software.amazon.smithy.aws.swift.codegen.customization.s3

import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.transform.ModelTransformer
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.model.expectShape

class S3Expires : SwiftIntegration {

    override fun enabledForService(model: Model, settings: SwiftSettings): Boolean {
        return model.expectShape<ServiceShape>(settings.service).isS3
    }

    override fun preprocessModel(model: Model, settings: SwiftSettings): Model {
        // Find all the members named "Expires" in all of the structures
        // and change their shape from `Timestamp` to `String`
        val updates = model.structureShapes
            .flatMap { it.allMembers.values }
            .filter { it.memberName == "Expires" }
            .map {
                val builder = it.toBuilder()
                builder.target("smithy.api#String")
                builder.build()
            }
        return ModelTransformer.create().replaceShapes(model, updates)
    }
}
