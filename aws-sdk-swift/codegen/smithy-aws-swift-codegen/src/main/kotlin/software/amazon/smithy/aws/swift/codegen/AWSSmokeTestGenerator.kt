package software.amazon.smithy.aws.swift.codegen

import software.amazon.smithy.aws.traits.ServiceTrait
import software.amazon.smithy.model.node.ObjectNode
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SmokeTestGenerator
import software.amazon.smithy.swift.codegen.utils.toUpperCamelCase

class AWSSmokeTestGenerator(
    private val ctx: ProtocolGenerator.GenerationContext
) : SmokeTestGenerator(ctx) {
    // Filter out tests by name or tag at codegen time.
    // Each element must have the prefix "<service-name>:" before the test name or tag name.
    // E.g., "AWSS3:GetObjectTest" or "AWSS3:BucketTests"
    override val smokeTestIdsToIgnore = setOf<String>(
        // Add smoke test name to ignore here:
        // E.g., "AWSACM:GetCertificateFailure",
    )
    override val smokeTestTagsToIgnore = setOf<String>(
        // Add smoke test tag to ignore here:
        // E.g., "AWSACM:TagToIgnore",
    )

    override fun getServiceName(): String {
        return "AWS" + ctx.service.getTrait(ServiceTrait::class.java).get().sdkId.toUpperCamelCase()
    }

    override fun getClientName(): String {
        return ctx.service.getTrait(ServiceTrait::class.java).get().sdkId.toUpperCamelCase().removeSuffix("Service") + "Client"
    }

    override fun renderCustomFilePrivateVariables(writer: SwiftWriter) {
        writer.write("fileprivate let regionFromEnv = ProcessInfo.processInfo.environment[\"AWS_SMOKE_TEST_REGION\"]")
        writer.write("fileprivate let tagsToSkip = (ProcessInfo.processInfo.environment[\"AWS_SMOKE_TEST_SKIP_TAGS\"] ?? \"\").components(separatedBy: \",\")")
    }

    override fun handleVendorParams(vendorParams: ObjectNode, writer: SwiftWriter) {
        val nameToValueMappings = getFormattedVendorParams(vendorParams)
        nameToValueMappings.forEach { mapping ->
            writer.write("config.${mapping.key} = ${mapping.value}")
        }
    }

    // Converts trait definition vendor param key:value pairs to Swift SDK config field:value pairs.
    private fun getFormattedVendorParams(vendorParams: ObjectNode): Map<String, String> {
        val formattedMapping = mutableMapOf<String, String>()
        vendorParams.members.forEach { originalMapping ->
            when (originalMapping.key.value) {
                /* BaseAwsVendorParams members */
                "region" -> {
                    // Take region value retrieved from environment variable if present; otherwise, take from trait definition.
                    val regionValue = "regionFromEnv ?? \"${originalMapping.value.expectStringNode().value}\""
                    formattedMapping.put("region", regionValue)
                    formattedMapping.put("signingRegion", regionValue)
                }
                "sigv4aRegionSet" -> { /* no-op; setting multiple signing regions in config is unsupported atm. */ }
                "uri" -> { formattedMapping.put("endpoint", "\"${originalMapping.value.expectStringNode().value}\"") }
                "useFips" -> { formattedMapping.put("useFIPS", originalMapping.value.expectBooleanNode().value.toString()) }
                "useDualstack" -> { formattedMapping.put("useDualStack", originalMapping.value.expectBooleanNode().value.toString()) }
                "useAccountIdRouting" -> { /* no-op; setting account ID routing in config is unsupported atm. */ }

                /* S3VendorParams members */
                "useAccelerate" -> { formattedMapping.put("accelerate", originalMapping.value.expectBooleanNode().value.toString()) }
                "useMultiRegionAccessPoints" -> {
                    // Name for corresponding config in Swift SDK is: `disableMultiRegionAccessPoints`; value needs to be flipped.
                    formattedMapping.put("disableMultiRegionAccessPoints", (!(originalMapping.value.expectBooleanNode().value)).toString())
                }
                "useGlobalEndpoint", "forcePathStyle", "useArnRegion" -> {
                    // No change needed for these
                    formattedMapping.put(originalMapping.key.value, originalMapping.value.expectBooleanNode().value.toString())
                }
            }
        }
        return formattedMapping
    }
}
