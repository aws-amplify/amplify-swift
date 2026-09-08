//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSComprehend
import AWSPolly
import AWSRekognition
import AWSTextract
import AWSTranslate
import Foundation

/// - Note: `Sendable` because the `static let` service accessors below must be concurrency-safe.
public struct PredictionsAWSService<Client>: Sendable {
    let fetch: @Sendable (AWSPredictionsService) -> Client
}

public extension PredictionsAWSService where Client == RekognitionClientProtocol {
    static let rekognition = Self(fetch: \.awsRekognition)
}

public extension PredictionsAWSService where Client == TranslateClientProtocol {
    static let translate = Self(fetch: \.awsTranslate)
}

public extension PredictionsAWSService where Client == PollyClientProtocol {
    static let polly = Self(fetch: \.awsPolly)
}

public extension PredictionsAWSService where Client == ComprehendClientProtocol {
    static let comprehend = Self(fetch: \.awsComprehend)
}

public extension PredictionsAWSService where Client == TextractClientProtocol {
    static let textract = Self(fetch: \.awsTextract)
}
