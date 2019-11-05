//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore

extension AWSPredictionsPlugin {

    public func configure(using configuration: Any) throws {
        let authService = AWSAuthService()
        let cognitoCredentialsProvider = authService.getCognitoCredentialsProvider()
        let predictionsService = try AWSPredictionsService(region: .USEast1,
                                                       cognitoCredentialsProvider: cognitoCredentialsProvider,
                                                       identifier: key)

        configure(predictionsService: predictionsService, authService: authService)
    }

    func configure(predictionsService: AWSPredictionsService,
                   authService: AWSAuthServiceBehavior,
                   queue: OperationQueue = OperationQueue()) {
        self.predictionsService = predictionsService
        self.authService = authService
        self.queue = queue
    }
}
