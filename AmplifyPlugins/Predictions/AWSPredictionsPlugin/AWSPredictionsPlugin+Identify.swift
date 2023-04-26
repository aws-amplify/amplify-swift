//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
@_spi(PredictionsConvertRequestKind) import Amplify
import AWSPolly

extension AWSPredictionsPlugin {
    public func identify<Output>(
        _ request: Predictions.Identify.Request<Output>,
        in image: URL,
        options: Predictions.Identify.Options?
    ) async throws -> Output {
        let multiService = IdentifyMultiService(
            request: request,
            url: image,
            coreMLService: coreMLService,
            predictionsService: predictionsService
        )

        let options = options ?? .init()
        switch options.defaultNetworkPolicy {
        case .offline:
            let offlineResult = try await multiService.offlineResult()
            return offlineResult
        case .auto, .online:
            let online = try await multiService.onlineResult()
            return online
        }
    }
}
