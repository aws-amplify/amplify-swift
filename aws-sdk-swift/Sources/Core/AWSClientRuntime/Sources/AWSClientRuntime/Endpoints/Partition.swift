//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import ClientRuntime

public struct Partition {

    /// The partition name/id e.g. "aws"
    let id: String

    /// The regular expression that specified the pattern that region names in the endpoint adhere to
    let regionRegex: String

    /// Endpoint that works across all regions or if [isRegionalized] is false
    let partitionEndpoint: String

    /// Flag indicating whether or not the service is regionalized in the partition. Some services have only a single,
    /// partition-global endpoint (e.g. CloudFront).
    let isRegionalized: Bool

    /**
     Default endpoint values for the partition. Some or all of the defaults specified may be superseded
     by an entry in [endpoints].
     */
    let defaults: ServiceEndpointMetadata

    /// Map of endpoint names to their definitions
    let endpoints: [String: ServiceEndpointMetadata]

    public init(id: String,
                regionRegex: String,
                partitionEndpoint: String,
                isRegionalized: Bool,
                defaults: ServiceEndpointMetadata,
                endpoints: [String: ServiceEndpointMetadata]) {
        self.id = id
        self.regionRegex = regionRegex
        self.partitionEndpoint = partitionEndpoint
        self.isRegionalized = isRegionalized
        self.defaults = defaults
        self.endpoints = endpoints
    }

    public func canResolveEndpoint(region: String) -> Bool {
        return endpoints[region] != nil || region.range(of: regionRegex,
                                                        options: .regularExpression) != nil
    }

    public func resolveEndpoint(region: String) throws -> AWSEndpoint {
        let shouldUsePartitionEndpoint = region.isEmpty && !partitionEndpoint.isEmpty
        let resolvedRegion = shouldUsePartitionEndpoint ? partitionEndpoint : region
        let endpointDefinition = endpointDefinitionForRegion(region: resolvedRegion)
        return try endpointDefinition.resolve(region: region, defaults: defaults)
    }

    public func endpointDefinitionForRegion(region: String) -> ServiceEndpointMetadata {
        if let endpointMetadata = endpoints[region] {
            return endpointMetadata
        } else if !isRegionalized {
            return endpoints[partitionEndpoint] ?? ServiceEndpointMetadata()
        } else {
            return ServiceEndpointMetadata()
        }
    }
}
