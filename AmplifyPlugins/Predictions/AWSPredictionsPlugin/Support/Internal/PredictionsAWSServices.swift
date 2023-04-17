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

public struct PredictionsAWSService<T> {
    let fetch: (AWSPredictionsService) -> T
}

extension PredictionsAWSService where T == RekognitionClient {
    public static let rekognition = Self(fetch: { $0.awsRekognition.getRekognition() })
}

extension PredictionsAWSService where T == TranslateClient {
    public static let translate = Self(fetch: { $0.awsTranslate.getTranslate() })
}

extension PredictionsAWSService where T == PollyClient {
    public static let polly = Self(fetch: { $0.awsPolly.getPolly() })
}

extension PredictionsAWSService where T == ComprehendClient {
    public static let comprehend = Self(fetch: { $0.awsComprehend.getComprehend() })
}

extension PredictionsAWSService where T == TextractClient {
    public static let textract = Self(fetch: { $0.awsTextract.getTextract() })
}
