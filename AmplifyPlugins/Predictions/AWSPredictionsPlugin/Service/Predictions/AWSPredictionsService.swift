//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSRekognition
import AWSTranslate

class AWSPredictionsService: AWSRekognitionServiceBehaviour, AWSTranslateServiceBehaviour {

    var identifier: String!
    var awsTranslate: AWSTranslateBehavior!
    var awsRekognition: AWSRekognitionBehavior!
    var awsPolly: AWSPollyBehavior!
    var awsTranscribe: AWSTranscribeBehavior!
    var awsComprehend: AWSComprehendBehavior!

    convenience init(region: AWSRegionType,
                     cognitoCredentialsProvider: AWSCognitoCredentialsProvider,
                     identifier: String) throws {
        let serviceConfigurationOptional = AWSServiceConfiguration(region: region,
                                                                   credentialsProvider: cognitoCredentialsProvider)

        guard let serviceConfiguration = serviceConfigurationOptional else {
            throw PluginError.pluginConfigurationError(
                PluginErrorConstants.serviceConfigurationInitializationError.errorDescription,
                PluginErrorConstants.serviceConfigurationInitializationError.recoverySuggestion)
        }

        AWSTranslate.register(with: serviceConfiguration, forKey: identifier)
        let awsTranslate = AWSTranslate(forKey: identifier)
        let awsTranslateAdapter = AWSTranslateAdapter(awsTranslate)
        AWSRekognition.register(with: serviceConfiguration, forKey: identifier)
        let awsRekognition = AWSRekognition(forKey: identifier)

        let awsRekognitionAdapter = AWSRekognitionAdapter(awsRekognition)

        self.init(awsTranslate: awsTranslateAdapter,
                  awsRekognition: awsRekognitionAdapter,
                  identifier: identifier)
    }

    init(awsTranslate: AWSTranslateBehavior,
         awsRekognition: AWSRekognitionBehavior,
         identifier: String) {
        self.awsTranslate = awsTranslate
        self.awsRekognition = awsRekognition
        self.identifier = identifier
    }

    func reset() {
        AWSTranslate.remove(forKey: identifier)
        awsTranslate = nil
        identifier = nil

        AWSRekognition.remove(forKey: identifier)
        awsRekognition = nil
        identifier = nil
    }

    func getEscapeHatch(key: PredictionsAWSServices) -> AWSService {
        switch key {
        case .rekognition:
            return awsRekognition.getRekognition()
        case .translate:
            return awsTranslate.getTranslate()
        case .polly:
            return awsPolly.getPolly()
        case .transcribe:
            return awsTranscribe.getTranscribe()
        case .comprehend:
            return awsComprehend.getComprehend()
        }
    }

}
