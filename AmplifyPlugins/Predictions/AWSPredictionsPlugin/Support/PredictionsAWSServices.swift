//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSTranslate
import AWSRekognition
import AWSPolly
import AWSComprehend
import AWSTextract

public struct PredictionsAWSService<Client> {
    let fetch: (AWSPredictionsService) -> Client
}

extension PredictionsAWSService where Client == RekognitionClientProtocol {
    public static let rekognition = Self(fetch: \.awsRekognition)
}

extension PredictionsAWSService where Client == TranslateClientProtocol {
    public static let translate = Self(fetch: \.awsTranslate)
}

extension PredictionsAWSService where Client == PollyClientProtocol {
    public static let polly = Self(fetch: \.awsPolly)
}

extension PredictionsAWSService where Client == ComprehendClientProtocol {
    public static let comprehend = Self(fetch: \.awsComprehend)
}

extension PredictionsAWSService where Client == TextractClientProtocol {
    public static let textract = Self(fetch: \.awsTextract)
}
