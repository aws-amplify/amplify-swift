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
import AWSPolly

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

        guard let identifyServiceConfiguration = AWSPredictionsService.makeIdentifyAWSServiceConfiguration(
            fromConfig: config,
            cognitoCredentialsProvider: cognitoCredentialsProvider),
            let convertServiceConfiguration = AWSPredictionsService.makeConvertAWSServiceConfiguration(
                fromConfig: config,
                cognitoCredentialsProvider: cognitoCredentialsProvider),
            let interpretServiceConfiguration = AWSPredictionsService.makeInterpretAWSServiceConfiguration(
                fromConfig: config,
                cognitoCredentialsProvider: cognitoCredentialsProvider) else {
            throw PluginError.pluginConfigurationError(
                PluginErrorMessage.serviceConfigurationInitializationError.errorDescription,
                PluginErrorMessage.serviceConfigurationInitializationError.recoverySuggestion)
        }

        let awsTranslateAdapter = AWSPredictionsService.makeAWSTranslate(
            convertServiceConfiguration: convertServiceConfiguration,
            identifier: identifier)

        let awsRekognitionAdapter = AWSPredictionsService.makeRekognition(
            identifyServiceConfiguration: identifyServiceConfiguration,
            identifier: identifier)

        let awsTextractAdapter = AWSPredictionsService.makeTextract(
            identifyServiceConfiguration: identifyServiceConfiguration,
            identifier: identifier)

        let awsComprehendAdapter = AWSPredictionsService.makeComprehend(
            interpretServiceConfiguration: interpretServiceConfiguration,
            identifier: identifier)

        let awsPollyAdapter = AWSPredictionsService.makePolly(
            convertServiceConfiguration: convertServiceConfiguration,
            identifier: identifier)

        self.init(identifier: identifier,
                  awsTranslate: awsTranslateAdapter,
                  awsRekognition: awsRekognitionAdapter,
                  awsTextract: awsTextractAdapter,
                  awsComprehend: awsComprehendAdapter,
                  awsPolly: awsPollyAdapter,
                  config: config)

    }

    init(identifier: String,
         awsTranslate: AWSTranslateBehavior,
         awsRekognition: AWSRekognitionBehavior,
         awsTextract: AWSTextractBehavior,
         awsComprehend: AWSComprehendBehavior,
         awsPolly: AWSPollyBehavior,
         config: AWSPredictionsPluginConfiguration) {

        self.identifier = identifier
        self.awsTranslate = awsTranslate
        self.awsRekognition = awsRekognition
        self.awsTextract = awsTextract
        self.awsComprehend = awsComprehend
        self.awsPolly = awsPolly
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

        AWSPolly.remove(forKey: identifier)
        awsPolly = nil

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

    private static func makeConvertAWSServiceConfiguration(
        fromConfig config: AWSPredictionsPluginConfiguration,
        cognitoCredentialsProvider: AWSCognitoCredentialsProvider) -> AWSServiceConfiguration? {
        let convertServiceConfigurationOptional = AWSServiceConfiguration(
            region: config.convertConfig?.region ?? config.defaultProjectRegion,
            credentialsProvider: cognitoCredentialsProvider)

        return convertServiceConfigurationOptional
    }

    private static func makeIdentifyAWSServiceConfiguration(
        fromConfig config: AWSPredictionsPluginConfiguration,
        cognitoCredentialsProvider: AWSCognitoCredentialsProvider) -> AWSServiceConfiguration? {
        let identifyServiceConfigurationOptional = AWSServiceConfiguration(
            region: config.identifyConfig?.region ?? config.defaultProjectRegion,
            credentialsProvider: cognitoCredentialsProvider)

        return identifyServiceConfigurationOptional
    }

    private static func makeInterpretAWSServiceConfiguration(
        fromConfig config: AWSPredictionsPluginConfiguration,
        cognitoCredentialsProvider: AWSCognitoCredentialsProvider) -> AWSServiceConfiguration? {
        let interpretServiceConfigurationOptional = AWSServiceConfiguration(
            region: config.interpretConfig?.region ?? config.defaultProjectRegion,
            credentialsProvider: cognitoCredentialsProvider)

        return interpretServiceConfigurationOptional
    }

    private static func makeAWSTranslate(
        convertServiceConfiguration: AWSServiceConfiguration,
        identifier: String) -> AWSTranslateAdapter {

        AWSTranslate.register(with: convertServiceConfiguration, forKey: identifier)
        let awsTranslate = AWSTranslate(forKey: identifier)
        return AWSTranslateAdapter(awsTranslate)
    }

    private static func makeRekognition(
        identifyServiceConfiguration: AWSServiceConfiguration,
        identifier: String) -> AWSRekognitionAdapter {
        AWSRekognition.register(with: identifyServiceConfiguration, forKey: identifier)
        let awsRekognition = AWSRekognition(forKey: identifier)
        return AWSRekognitionAdapter(awsRekognition)
    }

    private static func makeTextract(
        identifyServiceConfiguration: AWSServiceConfiguration,
        identifier: String) -> AWSTextractAdapter {
        AWSTextract.register(with: identifyServiceConfiguration, forKey: identifier)
        let awsTextract = AWSTextract(forKey: identifier)
        return AWSTextractAdapter(awsTextract)
    }

    private static func makePolly(
        convertServiceConfiguration: AWSServiceConfiguration,
        identifier: String) -> AWSPollyAdapter {
        AWSPolly.register(with: convertServiceConfiguration, forKey: identifier)
        let awsPolly = AWSPolly(forKey: identifier)
        return AWSPollyAdapter(awsPolly)
    }

    private static func makeComprehend(
        interpretServiceConfiguration: AWSServiceConfiguration,
        identifier: String) -> AWSComprehendAdapter {
        AWSComprehend.register(with: interpretServiceConfiguration, forKey: identifier)
        let awsComprehend = AWSComprehend(forKey: identifier)
        return AWSComprehendAdapter(awsComprehend)
    }
}
