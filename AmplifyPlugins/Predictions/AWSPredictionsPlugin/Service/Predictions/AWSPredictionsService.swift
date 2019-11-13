//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSRekognition
import AWSTranslate
import AWSTextract
import AWSComprehend

class AWSPredictionsService {

    var identifier: String!
    var awsTranslate: AWSTranslateBehavior!
    var awsRekognition: AWSRekognitionBehavior!
    var awsPolly: AWSPollyBehavior!
    var awsTranscribe: AWSTranscribeBehavior!
    var awsComprehend: AWSComprehendBehavior!
    var awsTextract: AWSTextractBehavior!
    var collectionId: String?
    var maxFaces: Int!

    convenience init(region: AWSRegionType,
                     collectionId: String?,
                     maxFaces: Int,
                     cognitoCredentialsProvider: AWSCognitoCredentialsProvider,
                     identifier: String) throws {
        let serviceConfigurationOptional = AWSServiceConfiguration(region: region,
                                                                   credentialsProvider: cognitoCredentialsProvider)

        guard let serviceConfiguration = serviceConfigurationOptional else {
            throw PluginError.pluginConfigurationError(
                PluginErrorMessage.serviceConfigurationInitializationError.errorDescription,
                PluginErrorMessage.serviceConfigurationInitializationError.recoverySuggestion)
        }

        AWSTranslate.register(with: serviceConfiguration, forKey: identifier)
        let awsTranslate = AWSTranslate(forKey: identifier)
        let awsTranslateAdapter = AWSTranslateAdapter(awsTranslate)

        AWSRekognition.register(with: serviceConfiguration, forKey: identifier)
        let awsRekognition = AWSRekognition(forKey: identifier)
        let awsRekognitionAdapter = AWSRekognitionAdapter(awsRekognition)
        AWSTextract.register(with: serviceConfiguration, forKey: identifier)
        let awsTextract = AWSTextract(forKey: identifier)
        let awsTextractAdapter = AWSTextractAdapter(awsTextract)

        AWSComprehend.register(with: serviceConfiguration, forKey: identifier)
               let awsComprehend = AWSComprehend(forKey: identifier)
               let awsComprehendAdapter = AWSComprehendAdapter(awsComprehend)

        self.init(awsTranslate: awsTranslateAdapter,
                  awsRekognition: awsRekognitionAdapter,
                  awsTextract: awsTextractAdapter,
                  awsComprehend: awsComprehendAdapter,
                  collectionId: collectionId,
                  maxFaces: maxFaces,
                  identifier: identifier)

    }

    init(awsTranslate: AWSTranslateBehavior,
         awsRekognition: AWSRekognitionBehavior,
         awsTextract: AWSTextractBehavior,
         awsComprehend: AWSComprehendBehavior,
         collectionId: String?,
         maxFaces: Int,
         identifier: String) {
        self.awsTranslate = awsTranslate
        self.awsRekognition = awsRekognition
        self.awsTextract = awsTextract
        self.identifier = identifier
        self.collectionId = collectionId
        self.maxFaces = maxFaces
        self.identifier = identifier
        self.awsTranslate = awsTranslate
        self.awsRekognition = awsRekognition
        self.awsComprehend = awsComprehend

    }

    func reset() {

        AWSTranslate.remove(forKey: identifier)
        awsTranslate = nil

        AWSRekognition.remove(forKey: identifier)
        awsRekognition = nil

        AWSTextract.remove(forKey: identifier)
        awsTextract = nil

        AWSComprehend.remove(forKey: identifier)
        awsComprehend = nil

        identifier = nil
    }

    func getEscapeHatch(key: PredictionsAWSService) -> AWSService {
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
        case .textract:
            return awsTextract.getTextract()
        }
    }

}
