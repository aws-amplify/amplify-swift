//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify // Amplify.Auth
import AWSPluginsCore // AuthAWSCredentialsProvider
import AwsCommonRuntimeKit // CommonRuntimeKit.initialize()
import AWSSDKHTTPAuth // AWSSigV4Signer
import Smithy // URIQueryItem
import SmithyHTTPAPI
import SmithyHTTPAuth
import SmithyHTTPAuthAPI
import SmithyIdentity // AWSCredentialIdentity

extension AWSCognitoAuthPlugin {


    /// Creates a AWS IAM SigV4 signer capable of signing AWS AppSync requests.
    ///
    /// **Note**. Although this method is static, **Amplify.Auth** is required to be configured with **AWSCognitoAuthPlugin** as
    /// it depends on the credentials provider from Cognito through `Amplify.Auth.fetchAuthSession()`. The static type allows
    /// developers to simplify their callsite without having to access the method on the plugin instance.
    ///
    /// - Parameter region: The region of the AWS AppSync API
    /// - Returns: A closure that takes in a requestand returns a signed request.
    public static func createAppSyncSigner(region: String) -> ((URLRequest) async throws -> URLRequest) {
        return { request in
            try await signAppSyncRequest(request, 
                                         region: region)
        }
    }

    private static var signer = {
        return AWSSigV4Signer()
    }()

    static func signAppSyncRequest(_ urlRequest: URLRequest,
                                   region: Swift.String,
                                   signingName: Swift.String = "appsync",
                                   date: Date = Date()) async throws -> URLRequest {
        CommonRuntimeKit.initialize()

        // Convert URLRequest to SDK's HTTPRequest
        guard let requestBuilder = try createAppSyncSdkHttpRequestBuilder(
            urlRequest: urlRequest) else {
            return urlRequest
        }

        // Retrieve the credentials from credentials provider
        let credentials: AWSCredentialIdentity
        let authSession = try await Amplify.Auth.fetchAuthSession()
        if let awsCredentialsProvider = authSession as? AuthAWSCredentialsProvider {
            let awsCredentials = try awsCredentialsProvider.getAWSCredentials().get()
            credentials = try awsCredentials.toAWSSDKCredentials()
        } else {
            let error = AuthError.unknown("Auth session does not include AWS credentials information")
            throw error
        }

        // Prepare signing
        let flags = SigningFlags(useDoubleURIEncode: true,
                                 shouldNormalizeURIPath: true,
                                 omitSessionToken: false)
        let signedBodyHeader: AWSSignedBodyHeader = .none
        let signedBodyValue: AWSSignedBodyValue = .empty
        let signingConfig = AWSSigningConfig(credentials: credentials,
                                             signedBodyHeader: signedBodyHeader,
                                             signedBodyValue: signedBodyValue,
                                             flags: flags,
                                             date: date,
                                             service: signingName,
                                             region: region,
                                             signatureType: .requestHeaders,
                                             signingAlgorithm: .sigv4)

        // Sign request
        guard let httpRequest = await signer.sigV4SignedRequest(
            requestBuilder: requestBuilder,

            signingConfig: signingConfig
        ) else {
            return urlRequest
        }

        // Update original request with new headers
        return setHeaders(from: httpRequest, to: urlRequest)
    }

    static func setHeaders(from sdkRequest: SmithyHTTPAPI.HTTPRequest, to urlRequest: URLRequest) -> URLRequest {
        var urlRequest = urlRequest
        for header in sdkRequest.headers.headers {
            urlRequest.setValue(header.value.joined(separator: ","), forHTTPHeaderField: header.name)
        }
        return urlRequest
    }

    static func createAppSyncSdkHttpRequestBuilder(urlRequest: URLRequest) throws -> HTTPRequestBuilder? {

        guard let url = urlRequest.url,
              let host = url.host else {
            return nil
        }

        var headers = urlRequest.allHTTPHeaderFields ?? [:]
        headers.updateValue(host, forKey: "host")

        let httpMethod = (urlRequest.httpMethod?.uppercased())
            .flatMap(HTTPMethodType.init(rawValue:)) ?? .get

        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?
            .map { URIQueryItem(name: $0.name, value: $0.value)} ?? []

        let requestBuilder = HTTPRequestBuilder()
            .withHost(host)
            .withPath(url.path)
            .withQueryItems(queryItems)
            .withMethod(httpMethod)
            .withPort(443)
            .withProtocol(.https)
            .withHeaders(.init(headers))
            .withBody(.data(urlRequest.httpBody))

        return requestBuilder
    }
}

extension AWSPluginsCore.AWSCredentials {

    func toAWSSDKCredentials() throws -> AWSCredentialIdentity {
        if let tempCredentials = self as? AWSTemporaryCredentials {
            return AWSCredentialIdentity(
                accessKey: tempCredentials.accessKeyId,
                secret: tempCredentials.secretAccessKey,
                expiration: tempCredentials.expiration,
                sessionToken: tempCredentials.sessionToken
            )
        } else {
            return AWSCredentialIdentity(
                accessKey: accessKeyId,
                secret: secretAccessKey,
                expiration: nil
            )
        }
    }
}
