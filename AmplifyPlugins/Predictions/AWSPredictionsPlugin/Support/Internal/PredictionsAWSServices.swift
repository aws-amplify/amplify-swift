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

public enum PredictionsAWSService {
    case rekognition
    case translate
//    case transcribe TODO: transcribe
    case polly
    case comprehend
    case textract
}

//struct PredictionsAWSService<Service, Client> {
//    let escape: (Service) -> Client
//}
//
//extension PredictionsAWSService where Service == AWSTranslateBehavior,
//                                        Client == TranslateClient {
//
//    static let translate: Self = .init() { translateBehavior in
//        return translateBehavior.getTranslate()
//    }
//}
