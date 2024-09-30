package software.amazon.smithy.aws.swift.codegen.customization.route53

import software.amazon.smithy.model.node.Node
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.traits.AnnotationTrait

/**
 * Indicates that a member should have the `hostedzone` prefix stripped if needed
 */
class TrimHostedZone : AnnotationTrait(ID, Node.objectNode()) {
    companion object {
        val ID = ShapeId.from("aws.api.internal#trimHostedZone")
    }
}
