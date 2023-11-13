//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

typealias AWSRegionType = String

struct IAMURLRequestInterceptor: URLRequestInterceptor {
    let iamCredentialsProvider: IAMCredentialsProvider
    let region: AWSRegionType
    let endpointType: AWSAPICategoryPluginEndpointType
    private let userAgent = AmplifyAWSServiceConfiguration.userAgentLib
    
    init(iamCredentialsProvider: IAMCredentialsProvider,
         region: AWSRegionType,
         endpointType: AWSAPICategoryPluginEndpointType) {
        self.iamCredentialsProvider = iamCredentialsProvider
        self.region = region
        self.endpointType = endpointType
    }

    func intercept(_ request: URLRequest) async throws -> URLRequest {
        guard let url = request.url else {
            throw APIError.unknown("Could not get url from mutable request", "")
        }

        let credentials = try await iamCredentialsProvider._credentialsProvider().fetchCredentials()

        let signingName: String
        switch endpointType {
        case .graphQL:
            signingName = URLRequestConstants.appSyncServiceName
        case .rest:
            signingName = URLRequestConstants.apiGatewayServiceName
        }

        let signer = SigV4Signer(
            credentials: credentials,
            serviceName: signingName,
            region: region
        )

        let httpMethod = (request.httpMethod?.uppercased())
            .flatMap(HTTPMethod.init(verb:)) ?? .get

        let signedRequest = signer.sign(
            url: url,
            method: httpMethod,
            body: .data(request.httpBody ?? .init()),
            headers: [
                URLRequestConstants.Header.userAgent: userAgent
            ]
        )

        return signedRequest
    }
}
