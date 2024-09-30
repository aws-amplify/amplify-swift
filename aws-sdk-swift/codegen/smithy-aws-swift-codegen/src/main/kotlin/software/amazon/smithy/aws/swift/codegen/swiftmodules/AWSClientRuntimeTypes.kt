package software.amazon.smithy.aws.swift.codegen.swiftmodules

import software.amazon.smithy.aws.swift.codegen.AWSSwiftDependency
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftDeclaration
import software.amazon.smithy.swift.codegen.swiftmodules.SwiftSymbol

object AWSClientRuntimeTypes {

    object AWSQuery {
        val AWSQueryError = runtimeSymbol("AWSQueryError", SwiftDeclaration.STRUCT, listOf("SmithyReadWrite"))
    }
    object EC2Query {
        val EC2QueryError = runtimeSymbol("EC2QueryError", SwiftDeclaration.STRUCT, listOf("SmithyReadWrite"))
    }
    object AWSJSON {
        val AWSJSONError = runtimeSymbol("AWSJSONError", SwiftDeclaration.STRUCT, listOf("SmithyReadWrite"))
        val XAmzTargetMiddleware = runtimeSymbol("XAmzTargetMiddleware", SwiftDeclaration.STRUCT)
    }
    object RestJSON {
        val RestJSONError = runtimeSymbol("RestJSONError", SwiftDeclaration.STRUCT, listOf("SmithyReadWrite"))
    }

    object RestXML {
        val RestXMLError = runtimeSymbol("RestXMLError", SwiftDeclaration.STRUCT, listOf("SmithyReadWrite"))
        object S3 {
            val AWSS3ServiceError = runtimeSymbol("AWSS3ServiceError", SwiftDeclaration.PROTOCOL, listOf("SmithyReadWrite"))
            val AWSS3ErrorWith200StatusXMLMiddleware = runtimeSymbol("AWSS3ErrorWith200StatusXMLMiddleware", SwiftDeclaration.STRUCT)
        }
    }

    object Core {
        val AWSUserAgentMetadata = runtimeSymbol("AWSUserAgentMetadata", SwiftDeclaration.STRUCT)
        val UserAgentMiddleware = runtimeSymbol("UserAgentMiddleware", SwiftDeclaration.STRUCT)
        val EndpointResolverMiddleware = runtimeSymbol("EndpointResolverMiddleware", SwiftDeclaration.STRUCT)
        val UnknownAWSHTTPServiceError = runtimeSymbol("UnknownAWSHTTPServiceError", SwiftDeclaration.STRUCT, listOf("UnknownAWSHTTPServiceError"))
        val AWSServiceError = runtimeSymbol("AWSServiceError", SwiftDeclaration.PROTOCOL)
        val Sha256TreeHashMiddleware = runtimeSymbol("Sha256TreeHashMiddleware", SwiftDeclaration.STRUCT)
        val AWSRetryErrorInfoProvider = runtimeSymbol("AWSRetryErrorInfoProvider", SwiftDeclaration.ENUM)
        val AWSRetryMode = runtimeSymbol("AWSRetryMode", SwiftDeclaration.ENUM)
        val AWSPartitionDefinition = runtimeSymbol("awsPartitionJSON", SwiftDeclaration.LET)
        val AWSDefaultClientConfiguration = runtimeSymbol("AWSDefaultClientConfiguration", SwiftDeclaration.PROTOCOL)
        val AWSRegionClientConfiguration = runtimeSymbol("AWSRegionClientConfiguration", SwiftDeclaration.PROTOCOL)
        val AWSClientConfigDefaultsProvider = runtimeSymbol("AWSClientConfigDefaultsProvider", SwiftDeclaration.CLASS)
        val DefaultAWSClientPlugin = runtimeSymbol("DefaultAWSClientPlugin", SwiftDeclaration.CLASS)
        val Route53TrimHostedZoneMiddleware = runtimeSymbol("Route53TrimHostedZoneMiddleware", SwiftDeclaration.STRUCT)
        val FlexibleChecksumsRequestMiddleware =
            runtimeSymbol("FlexibleChecksumsRequestMiddleware", SwiftDeclaration.STRUCT)
        val FlexibleChecksumsResponseMiddleware =
            runtimeSymbol("FlexibleChecksumsResponseMiddleware", SwiftDeclaration.STRUCT)
        val AmzSdkInvocationIdMiddleware = runtimeSymbol("AmzSdkInvocationIdMiddleware", SwiftDeclaration.STRUCT)
        val AmzSdkRequestMiddleware = runtimeSymbol("AmzSdkRequestMiddleware", SwiftDeclaration.CLASS)
    }
}

private fun runtimeSymbol(
    name: String,
    declaration: SwiftDeclaration,
    spiNames: List<String> = emptyList(),
): Symbol = SwiftSymbol.make(
    name,
    declaration,
    AWSSwiftDependency.AWS_CLIENT_RUNTIME,
    emptyList(),
    spiNames,
)
