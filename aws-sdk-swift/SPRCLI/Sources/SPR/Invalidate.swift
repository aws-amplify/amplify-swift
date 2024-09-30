//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCLIUtils
import AWSCloudFront

extension SPRPublisher {

    public static func invalidate(region: String, distributionID: String?, invalidations: [String]) async throws {
        let cloudFrontClient = try CloudFrontClient(region: region)
        let resolvedDistributionID = resolvedDistributionID(from: distributionID)
        guard let resolvedDistributionID, !resolvedDistributionID.isEmpty else {
            throw Error("CloudFront DistributionID not provided")
        }
        let invalidationPaths = invalidations.map { "/\($0)" }
        let invalidationBatch = CloudFrontClientTypes.InvalidationBatch(callerReference: UUID().uuidString, paths: CloudFrontClientTypes.Paths(items: invalidationPaths, quantity: invalidationPaths.count))
        let input = CreateInvalidationInput(distributionId: distributionID, invalidationBatch: invalidationBatch)
        _ = try await cloudFrontClient.createInvalidation(input: input)
    }
}
