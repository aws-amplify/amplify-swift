//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import AmplifyFoundation
import AmplifyFoundationBridge
import AwsCommonRuntimeKit
import AWSSDKHTTPAuth
import Foundation
import Smithy
import SmithyHTTPAPI
import SmithyHTTPAuth
import SmithyHTTPAuthAPI
import XCTest

/// Signing a request with a session's AWS credentials.
///
/// The plugin's `AWSCognitoAuthPlugin.createAppSyncSigner(region:)` is a static helper over
/// `Amplify.Auth` (plugin-only). The client's equivalent is its `credentialsProvider`, wrapped in
/// AmplifyFoundationBridge's `FoundationToSDKCredentialsAdapter` and handed to the SDK's SigV4 signer, with
/// the signing configuration the plugin's signer uses. The AppSync request is not sent (the plugin case
/// asserts only its signed headers); an STS `GetCallerIdentity` signed the same way is, to prove the
/// signature valid.
final class SigningTests: ClientIntegrationTestCase {

    /// A guest session's credentials provider signs an AppSync request (SG-1; the plugin's
    /// `testSignAppSyncRequest`).
    ///
    /// - Given: a fresh session made a guest by `fetchAuthSession()`, over R-IP
    /// - When:
    ///    - the plugin test's request (`GET graphql.com?param=value`) is signed for `appsync` in
    ///      `us-east-1` with the SDK's `AWSSigV4Signer`, its identity resolved through
    ///      `FoundationToSDKCredentialsAdapter(provider: client.credentialsProvider)`
    /// - Then:
    ///    - the signed request's headers are exactly `Authorization`, `X-Amz-Security-Token` and `X-Amz-Date`, the
    ///      plugin test's three
    ///    - `Authorization` is SigV4 for the guest session's own access key, scoped to `us-east-1/appsync`,
    ///      and its signed headers are exactly `x-amz-date` and `x-amz-security-token`, as with the plugin's
    ///      signer (the request, like the plugin's, sets no `Host` header, so none is signed);
    ///      `X-Amz-Security-Token` is the session's own token
    ///    - the same signer and configuration, for `sts` in the identity pool's region and with the `Host`
    ///      header an AWS service requires signed, sign an STS `GetCallerIdentity` that STS accepts,
    ///      answering as the unauthenticated role: the signature is valid, not only well formed
    ///
    func testCredentialsProviderSignsAnAppSyncRequest() async throws {
        let client = try makeClient("guest-signer")
        let credentials = try await client.fetchAuthSession().awsCredentialsResult.get()

        let signed = try await Self.sign(
            host: "graphql.com",
            query: [URIQueryItem(name: "param", value: "value")],
            service: "appsync",
            region: "us-east-1",
            with: client.credentialsProvider
        )

        let headers = signed.headers
        let names = Set(headers.headers.map { $0.name.lowercased() })
        XCTAssertEqual(names, ["authorization", "x-amz-security-token", "x-amz-date"], "exactly the plugin test's three headers")
        XCTAssertEqual(headers.headers.count, 3, "no header twice")
        let authorization = try XCTUnwrap(headers.value(for: "Authorization"))
        XCTAssertTrue(
            authorization.hasPrefix("AWS4-HMAC-SHA256 Credential=\(credentials.accessKeyId)/"),
            "the signature is not SigV4 for the session's own access key"
        )
        XCTAssertTrue(authorization.contains("/us-east-1/appsync/aws4_request"), "the credential scope is not us-east-1/appsync")
        let signedHeaders = authorization.range(of: "SignedHeaders=[^,]*", options: .regularExpression)
            .map { authorization[$0].dropFirst("SignedHeaders=".count).split(separator: ";").map(String.init) }
        XCTAssertEqual(signedHeaders.map(Set.init), ["x-amz-date", "x-amz-security-token"])
        XCTAssertNotNil(authorization.range(of: "Signature=[0-9a-f]{64}$", options: .regularExpression), "no SigV4 signature")
        XCTAssertTrue(
            headers.value(for: "X-Amz-Security-Token") == credentials.sessionToken,
            "the security token is not the session's"
        )
        let date = try XCTUnwrap(headers.value(for: "X-Amz-Date"))
        XCTAssertNotNil(date.range(of: "^[0-9]{8}T[0-9]{6}Z$", options: .regularExpression), "X-Amz-Date is not ISO 8601 basic")

        let region = try XCTUnwrap(IntegrationTestEnvironment.configuration().identityPool).region
        let stsRequest = try await Self.sign(
            host: "sts.\(region).amazonaws.com",
            query: [URIQueryItem(name: "Action", value: "GetCallerIdentity"), URIQueryItem(name: "Version", value: "2011-06-15")],
            service: "sts",
            region: region,
            signingHost: true,
            with: client.credentialsProvider
        )
        let (body, response) = try await URLSession.shared.data(for: Self.urlRequest(from: stsRequest))
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200, "STS refused the signed request")
        let text = String(decoding: body, as: UTF8.self)
        let arn = text.range(of: "<Arn>[^<]*</Arn>", options: .regularExpression).map { String(text[$0].dropFirst(5).dropLast(6)) }
        let role = try XCTUnwrap(arn.flatMap(CallerIdentity.roleName(of:)), "STS returned no assumed-role ARN")
        XCTAssertTrue(role == (try SandboxRoles()).unauthenticatedRoleName, "the signed request answered as another role")
    }

    /// `GET https://<host>/?<query>`, SigV4-signed with the plugin signer's configuration and the provider's
    /// credentials through `FoundationToSDKCredentialsAdapter`. With `signingHost`, the request carries a
    /// `Host` header, which is then signed, as an AWS service requires; the plugin's AppSync request has none.
    private static func sign(
        host: String,
        query: [URIQueryItem],
        service: String,
        region: String,
        signingHost: Bool = false,
        with provider: any AWSCredentialsProvider
    ) async throws -> SmithyHTTPAPI.HTTPRequest {
        CommonRuntimeKit.initialize()
        let identity = try await FoundationToSDKCredentialsAdapter(provider: provider).getIdentity()
        let builder = HTTPRequestBuilder()
            .withHost(host)
            .withPath("/")
            .withQueryItems(query)
            .withMethod(.get)
            .withPort(443)
            .withProtocol(.https)
        if signingHost {
            builder.withHeader(name: "Host", value: host)
        }
        let signingConfig = AWSSigningConfig(
            credentials: identity,
            signedBodyHeader: .none,
            signedBodyValue: .empty,
            flags: SigningFlags(useDoubleURIEncode: true, shouldNormalizeURIPath: true, omitSessionToken: false),
            date: Date(),
            service: service,
            region: region,
            signatureType: .requestHeaders,
            signingAlgorithm: .sigv4
        )
        let signed = await AWSSigV4Signer().sigV4SignedRequest(requestBuilder: builder, signingConfig: signingConfig)
        return try XCTUnwrap(signed, "the signer returned no request")
    }

    /// The signed SDK request as a `URLRequest`, with every header the signer set, as the plugin's signer
    /// copies them onto the app's request.
    private static func urlRequest(from request: SmithyHTTPAPI.HTTPRequest) throws -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = request.destination.host
        components.path = "/"
        components.queryItems = request.destination.queryItems.map { URLQueryItem(name: $0.name, value: $0.value) }
        var urlRequest = URLRequest(url: try XCTUnwrap(components.url))
        urlRequest.httpMethod = "GET"
        for header in request.headers.headers {
            urlRequest.setValue(header.value.joined(separator: ","), forHTTPHeaderField: header.name)
        }
        return urlRequest
    }
}
