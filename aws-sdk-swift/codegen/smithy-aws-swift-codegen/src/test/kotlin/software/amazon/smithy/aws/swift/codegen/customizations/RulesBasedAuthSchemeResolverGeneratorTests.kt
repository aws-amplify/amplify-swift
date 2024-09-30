package software.amazon.smithy.aws.swift.codegen.customizations

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.aws.swift.codegen.TestContext
import software.amazon.smithy.aws.swift.codegen.TestUtils
import software.amazon.smithy.aws.swift.codegen.protocols.restjson.AWSRestJson1ProtocolGenerator
import software.amazon.smithy.aws.swift.codegen.shouldSyntacticSanityCheck
import software.amazon.smithy.aws.traits.protocols.RestJson1Trait

class RulesBasedAuthSchemeResolverGeneratorTests {
    // Note that there's no region field in
    //  auth scheme resolver params despite the service using SigV4 as one of its auth schemes,
    //  because no endpoint ruleset was provided for this test case.
    //  It's assumed in codden that endopint ruleset has the region field contained within.
    @Test
    fun `rules based auth scheme resolver generation test with fake S3 smithy model`() {
        val context = setupTests("rules-based-auth-resolver-test.smithy", "com.test#S3")
        val contents =
            TestUtils.getFileContents(context.manifest, "Sources/Example/AuthSchemeResolver.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
public struct S3AuthSchemeResolverParameters: SmithyHTTPAuthAPI.AuthSchemeResolverParameters {
    public let operation: Swift.String
}

public protocol S3AuthSchemeResolver: SmithyHTTPAuthAPI.AuthSchemeResolver {
    // Intentionally empty.
    // This is the parent protocol that all auth scheme resolver implementations of
    // the service S3 must conform to.
}

private struct InternalModeledS3AuthSchemeResolver: S3AuthSchemeResolver {

    public func resolveAuthScheme(params: SmithyHTTPAuthAPI.AuthSchemeResolverParameters) throws -> [SmithyHTTPAuthAPI.AuthOption] {
        var validAuthOptions = [SmithyHTTPAuthAPI.AuthOption]()
        guard let serviceParams = params as? S3AuthSchemeResolverParameters else {
            throw Smithy.ClientError.authError("Service specific auth scheme parameters type must be passed to auth scheme resolver.")
        }
        switch serviceParams.operation {
            case "onlyHttpApiKeyAuth":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#httpApiKeyAuth"))
            case "onlyHttpApiKeyAuthOptional":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#httpApiKeyAuth"))
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "onlyHttpBearerAuth":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#httpBearerAuth"))
            case "onlyHttpBearerAuthOptional":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#httpBearerAuth"))
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "onlyHttpApiKeyAndBearerAuth":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#httpApiKeyAuth"))
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#httpBearerAuth"))
            case "onlyHttpApiKeyAndBearerAuthReversed":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#httpBearerAuth"))
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#httpApiKeyAuth"))
            case "onlySigv4Auth":
                var sigV4Option = SmithyHTTPAuthAPI.AuthOption(schemeID: "aws.auth#sigv4")
                sigV4Option.signingProperties.set(key: SmithyHTTPAuthAPI.SigningPropertyKeys.signingName, value: "weather")
                guard let region = serviceParams.region else {
                    throw Smithy.ClientError.authError("Missing region in auth scheme parameters for SigV4 auth scheme.")
                }
                sigV4Option.signingProperties.set(key: SmithyHTTPAuthAPI.SigningPropertyKeys.signingRegion, value: region)
                validAuthOptions.append(sigV4Option)
            case "onlySigv4AuthOptional":
                var sigV4Option = SmithyHTTPAuthAPI.AuthOption(schemeID: "aws.auth#sigv4")
                sigV4Option.signingProperties.set(key: SmithyHTTPAuthAPI.SigningPropertyKeys.signingName, value: "weather")
                guard let region = serviceParams.region else {
                    throw Smithy.ClientError.authError("Missing region in auth scheme parameters for SigV4 auth scheme.")
                }
                sigV4Option.signingProperties.set(key: SmithyHTTPAuthAPI.SigningPropertyKeys.signingRegion, value: region)
                validAuthOptions.append(sigV4Option)
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "onlyCustomAuth":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "com.test#customAuth"))
            case "onlyCustomAuthOptional":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "com.test#customAuth"))
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            default:
                var sigV4Option = SmithyHTTPAuthAPI.AuthOption(schemeID: "aws.auth#sigv4")
                sigV4Option.signingProperties.set(key: SmithyHTTPAuthAPI.SigningPropertyKeys.signingName, value: "weather")
                guard let region = serviceParams.region else {
                    throw Smithy.ClientError.authError("Missing region in auth scheme parameters for SigV4 auth scheme.")
                }
                sigV4Option.signingProperties.set(key: SmithyHTTPAuthAPI.SigningPropertyKeys.signingRegion, value: region)
                validAuthOptions.append(sigV4Option)
        }
        return validAuthOptions
    }

    public func constructParameters(context: Smithy.Context) throws -> SmithyHTTPAuthAPI.AuthSchemeResolverParameters {
        return try DefaultS3AuthSchemeResolver().constructParameters(context: context)
    }
}

public struct DefaultS3AuthSchemeResolver: S3AuthSchemeResolver {

    public func resolveAuthScheme(params: SmithyHTTPAuthAPI.AuthSchemeResolverParameters) throws -> [SmithyHTTPAuthAPI.AuthOption] {
        var validAuthOptions = [SmithyHTTPAuthAPI.AuthOption]()
        guard let serviceParams = params as? S3AuthSchemeResolverParameters else {
            throw Smithy.ClientError.authError("Service specific auth scheme parameters type must be passed to auth scheme resolver.")
        }
        let endpointParams = EndpointParams(authSchemeParams: serviceParams)
        let endpoint = try DefaultEndpointResolver().resolve(params: endpointParams)
        guard let authSchemes = endpoint.authSchemes() else {
            return try InternalModeledS3AuthSchemeResolver().resolveAuthScheme(params: params)
        }
        let schemes = try authSchemes.map { (input) -> ClientRuntime.EndpointsAuthScheme in try ClientRuntime.EndpointsAuthScheme(from: input) }
        for scheme in schemes {
            switch scheme {
                case .sigV4(let param):
                    var sigV4Option = SmithyHTTPAuthAPI.AuthOption(schemeID: "aws.auth#sigv4")
                    sigV4Option.signingProperties.set(key: SmithyHTTPAuthAPI.SigningPropertyKeys.signingName, value: param.signingName)
                    sigV4Option.signingProperties.set(key: SmithyHTTPAuthAPI.SigningPropertyKeys.signingRegion, value: param.signingRegion)
                    validAuthOptions.append(sigV4Option)
                case .sigV4A(let param):
                    var sigV4Option = SmithyHTTPAuthAPI.AuthOption(schemeID: "aws.auth#sigv4a")
                    sigV4Option.signingProperties.set(key: SmithyHTTPAuthAPI.SigningPropertyKeys.signingName, value: param.signingName)
                    sigV4Option.signingProperties.set(key: SmithyHTTPAuthAPI.SigningPropertyKeys.signingRegion, value: param.signingRegionSet?[0])
                    validAuthOptions.append(sigV4Option)
                default:
                    throw Smithy.ClientError.authError("Unknown auth scheme name: \(scheme.name)")
            }
        }
        return validAuthOptions
    }

    public func constructParameters(context: Smithy.Context) throws -> SmithyHTTPAuthAPI.AuthSchemeResolverParameters {
        guard let opName = context.getOperation() else {
            throw Smithy.ClientError.dataNotFound("Operation name not configured in middleware context for auth scheme resolver params construction.")
        }
        guard let endpointParam = context.attributes.get(key: Smithy.AttributeKey<EndpointParams>(name: "EndpointParams")) else {
            throw Smithy.ClientError.dataNotFound("Endpoint param not configured in middleware context for rules-based auth scheme resolver params construction.")
        }
        return S3AuthSchemeResolverParameters(operation: opName)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestUtils.executeDirectedCodegen(smithyFile, serviceShapeId, RestJson1Trait.ID)

        val generator = AWSRestJson1ProtocolGenerator()
        generator.initializeMiddleware(context.ctx)
        generator.generateProtocolClient(context.ctx)
        generator.generateSerializers(context.ctx)
        context.ctx.delegator.flushWriters()
        return context
    }
}
