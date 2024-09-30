package software.amazon.smithy.aws.swift.codegen.customization

import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.traits.ClientOptionalTrait
import software.amazon.smithy.model.transform.ModelTransformer
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration

/**
 * Integration that pre-processes the model to box all unboxed primitives.
 *
 * See: https://github.com/awslabs/aws-sdk-swift/issues/272
 *
 * EC2 incorrectly models primitive shapes as unboxed when they actually
 * need to be boxed for the API to work properly (e.g. sending default values). The
 * rest of these services are at risk of similar behavior because they aren't true coral services
 */
class BoxServices : SwiftIntegration {
    override val order: Byte = -127

    private val serviceIds = listOf(
        "com.amazonaws.ec2#AmazonEC2",
        "com.amazonaws.nimble#nimble",
        "com.amazonaws.amplifybackend#AmplifyBackend",
        "com.amazonaws.apigatewaymanagementapi#ApiGatewayManagementApi",
        "com.amazonaws.apigatewayv2#ApiGatewayV2",
        "com.amazonaws.dataexchange#DataExchange",
        "com.amazonaws.greengrass#Greengrass",
        "com.amazonaws.iot1clickprojects#AWSIoT1ClickProjects",
        "com.amazonaws.kafka#Kafka",
        "com.amazonaws.macie2#Macie2",
        "com.amazonaws.mediaconnect#MediaConnect",
        "com.amazonaws.mediaconvert#MediaConvert",
        "com.amazonaws.medialive#MediaLive",
        "com.amazonaws.mediapackage#MediaPackage",
        "com.amazonaws.mediapackagevod#MediaPackageVod",
        "com.amazonaws.mediatailor#MediaTailor",
        "com.amazonaws.pinpoint#Pinpoint",
        "com.amazonaws.pinpointsmsvoice#PinpointSMSVoice",
        "com.amazonaws.serverlessapplicationrepository#ServerlessApplicationRepository",
        "com.amazonaws.mq#mq",
        "com.amazonaws.schemas#schemas",
    ).map(ShapeId::from)

    override fun enabledForService(model: Model, settings: SwiftSettings): Boolean =
        serviceIds.any { it == settings.service }

    override fun preprocessModel(model: Model, settings: SwiftSettings): Model {
        val updates = arrayListOf<Shape>()
        for (struct in model.structureShapes) {
            for (member in struct.allMembers.values) {
                updates.add(member.toBuilder().addTrait(ClientOptionalTrait()).build())
            }
        }
        return ModelTransformer.create().replaceShapes(model, updates)
    }
}
