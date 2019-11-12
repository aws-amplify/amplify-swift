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
    var predictionsConfig: AWSPredictionsPluginConfiguration!
    var rekognitionWordLimit = 50

    convenience init(config: AWSPredictionsPluginConfiguration,
                     cognitoCredentialsProvider: AWSCognitoCredentialsProvider,
                     identifier: String) throws {

        //TODO pull default region from top level config aws_project_region
        let defaultRegion: AWSRegionType = .USEast1

        let identifyServiceConfigurationOptional = AWSServiceConfiguration(
            region: config.identifyConfig?.region ?? defaultRegion,
            credentialsProvider: cognitoCredentialsProvider)

        let convertServiceConfigurationOptional = AWSServiceConfiguration(
            region: config.convertConfig?.region ?? defaultRegion,
            credentialsProvider: cognitoCredentialsProvider)

        let interpretServiceConfigurationOptional = AWSServiceConfiguration(
            region: config.interpretConfig?.region ?? defaultRegion,
            credentialsProvider: cognitoCredentialsProvider)

        guard let identifyServiceConfiguration = identifyServiceConfigurationOptional,
        let convertServiceConfiguration = convertServiceConfigurationOptional,
        let interpretServiceConfiguration = interpretServiceConfigurationOptional else {
            throw PluginError.pluginConfigurationError(
                PluginErrorMessage.serviceConfigurationInitializationError.errorDescription,
                PluginErrorMessage.serviceConfigurationInitializationError.recoverySuggestion)
        }

        AWSTranslate.register(with: convertServiceConfiguration, forKey: identifier)
        let awsTranslate = AWSTranslate(forKey: identifier)
        let awsTranslateAdapter = AWSTranslateAdapter(awsTranslate)

        AWSRekognition.register(with: identifyServiceConfiguration, forKey: identifier)
        let awsRekognition = AWSRekognition(forKey: identifier)
        let awsRekognitionAdapter = AWSRekognitionAdapter(awsRekognition)
        AWSTextract.register(with: identifyServiceConfiguration, forKey: identifier)
        let awsTextract = AWSTextract(forKey: identifier)
        let awsTextractAdapter = AWSTextractAdapter(awsTextract)

        AWSComprehend.register(with: interpretServiceConfiguration, forKey: identifier)
        let awsComprehend = AWSComprehend(forKey: identifier)
        let awsComprehendAdapter = AWSComprehendAdapter(awsComprehend)

        self.init(identifier: identifier,
                  awsTranslate: awsTranslateAdapter,
                  awsRekognition: awsRekognitionAdapter,
                  awsTextract: awsTextractAdapter,
                  awsComprehend: awsComprehendAdapter,
                  config: config)

    }

    init(identifier: String,
         awsTranslate: AWSTranslateBehavior,
         awsRekognition: AWSRekognitionBehavior,
         awsTextract: AWSTextractBehavior,
         awsComprehend: AWSComprehendBehavior,
         config: AWSPredictionsPluginConfiguration) {
        self.awsTranslate = awsTranslate
        self.awsRekognition = awsRekognition
        self.awsTextract = awsTextract
        self.awsTranslate = awsTranslate
        self.awsRekognition = awsRekognition
        self.awsComprehend = awsComprehend
        self.identifier = identifier
        self.predictionsConfig = config

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
