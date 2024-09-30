package software.amazon.smithy.aws.swift.codegen.model.traits

import software.amazon.smithy.model.node.Node
import software.amazon.smithy.model.node.ObjectNode
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.traits.AnnotationTrait

/**
 * This custom trait designates operations from which presigners can be generated.
 *
 * Operations decorated with this trait have been deemed useful to be called out of band
 * from a normal client-based operation call.  This may be due to the operation being embedded in
 * another operation call or the customer may wish to invoke the presigned request at a later time or in
 * some part of their software that does not have access to a service client instance.
 *
 * Behavior for how a operation is presignable is in some ways protocol specific:
 * restXml - for operations which require bodies as input, these are unsigned
 * awsQuery - GET calls are performed by mapping the body into the querystring
 *
 * This trait may be generalized to Smithy itself.  If this happens, this integration should be removed
 * entirely.
 */
class Presignable : AnnotationTrait {
    companion object {
        val ID: ShapeId = ShapeId.from("smithy.swift.traits#presignable")
    }
    constructor(node: ObjectNode) : super(ID, node)
    constructor() : this(Node.objectNode())
}
