//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AWSPredictionsPlugin {

    public func configure(using configuration: Any) throws {
        let authService = AWSAuthService()
        let cognitoCredentialsProvider = authService.getCognitoCredentialsProvider()
        let translateService = try AWSTranslateService(region: .USEast1,
                                                       cognitoCredentialsProvider: cognitoCredentialsProvider,
                                                       identifier: key)
        configure(translateService: translateService, authService: authService)
    }

    func configure(translateService: AWSTranslateServiceBehaviour,
                   authService: AWSAuthServiceBehavior,
                   queue: OperationQueue = OperationQueue()) {
        self.translateService = translateService
        self.authService = authService
        self.queue = queue
    }
}
