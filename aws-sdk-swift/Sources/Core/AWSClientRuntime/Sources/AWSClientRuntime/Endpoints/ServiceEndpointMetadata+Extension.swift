//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.URIScheme
import ClientRuntime
import SmithyHTTPAPI

extension ServiceEndpointMetadata {
    func resolve(region: String, defaults: ServiceEndpointMetadata) throws -> AWSEndpoint {
        let serviceEndpointMetadata = buildEndpointMetadataIfNotSet(defaults: defaults)
        guard let hostname = serviceEndpointMetadata.hostName else {
            throw EndpointError.hostnameIsNil("EndpointDefinition.hostname cannot be nil at this point")
        }
        let editedHostName = hostname.replacingOccurrences(of: "{region}", with: region)
        let transportProtocol = getProtocolByPriority(from: serviceEndpointMetadata.protocols)
        let signingName = serviceEndpointMetadata.credentialScope?.serviceId
        let signingRegion = serviceEndpointMetadata.credentialScope?.region ?? region

        return AWSEndpoint(endpoint: Endpoint(host: editedHostName,
                           path: "/",
                           protocolType: URIScheme(rawValue: transportProtocol)),
                           signingName: signingName,
                           signingRegion: signingRegion)
    }

    private func buildEndpointMetadataIfNotSet(defaults: ServiceEndpointMetadata) -> ServiceEndpointMetadata {
        let hostName = self.hostName ?? defaults.hostName
        let protocols = !self.protocols.isEmpty ? self.protocols : defaults.protocols
        let credentialScope = CredentialScope(
            region: self.credentialScope?.region ?? defaults.credentialScope?.region,
            serviceId: self.credentialScope?.serviceId ?? defaults.credentialScope?.serviceId
        )
        let signatureVersions = !self.signatureVersions.isEmpty ? self.signatureVersions : defaults.signatureVersions
        return ServiceEndpointMetadata(
            hostName: hostName,
            protocols: protocols,
            credentialScope: credentialScope,
            signatureVersions: signatureVersions
        )
    }

    private func getProtocolByPriority(from: [String]) -> String {
        guard from.isEmpty else {
            return defaultProtocol
        }

        for p in protocolPriority {
            if let candidate = from.first(where: { $0 == p}) {
                return candidate
            }
        }

        return defaultProtocol
    }
}
