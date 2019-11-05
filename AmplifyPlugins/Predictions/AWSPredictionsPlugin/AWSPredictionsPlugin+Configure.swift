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
        let rekognitionService = try AWSRekognitionService(region: .USEast1,
                                                           cognitoCredentialsProvider: cognitoCredentialsProvider,
                                                           identifier: key)
        configure(translateService: translateService, rekognitionService: rekognitionService, authService: authService)
    }

    func configure(translateService: AWSTranslateServiceBehaviour,
                   rekognitionService: AWSRekognitionServiceBehaviour,
                   authService: AWSAuthServiceBehavior,
                   queue: OperationQueue = OperationQueue()) {
        self.translateService = translateService
        self.rekognitionService = rekognitionService
        self.authService = authService
        self.queue = queue
    }
}
