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
import AWSPluginsCore
import AWSTranscribeStreaming

class AWSPredictionsService {

    var identifier: String!
    var awsTranslate: AWSTranslateBehavior!
    var awsRekognition: AWSRekognitionBehavior!
    var awsPolly: AWSPollyBehavior!
    var awsTranscribeStreaming: AWSTranscribeStreamingBehavior!
    var awsComprehend: AWSComprehendBehavior!
    var awsTextract: AWSTextractBehavior!
    var predictionsConfig: PredictionsPluginConfiguration!
    let rekognitionWordLimit = 50
    let transcribeDelegate: NativeWSTranscribeStreamingClientDelegate!
    let transcribeCallbackQueue: DispatchQueue!

    convenience init(configuration: PredictionsPluginConfiguration,
                     cognitoCredentialsProvider: AWSCognitoCredentialsProvider,
                     identifier: String) throws {

        let interpretServiceConfiguration = AmplifyAWSServiceConfiguration(region: configuration.interpret.region,
                                                                           credentialsProvider: cognitoCredentialsProvider)
        let identifyServiceConfiguration = AmplifyAWSServiceConfiguration(region: configuration.identify.region,
                                                                          credentialsProvider: cognitoCredentialsProvider)
        let convertServiceConfiguration =  AmplifyAWSServiceConfiguration(region: configuration.convert.region,
                                                                          credentialsProvider: cognitoCredentialsProvider)

        let awsTranslateAdapter = AWSPredictionsService.makeAWSTranslate(
            serviceConfiguration: convertServiceConfiguration,
            identifier: identifier)

        let awsRekognitionAdapter = AWSPredictionsService.makeRekognition(
            serviceConfiguration: identifyServiceConfiguration,
            identifier: identifier)

        let awsTextractAdapter = AWSPredictionsService.makeTextract(
            serviceConfiguration: identifyServiceConfiguration,
            identifier: identifier)

        let awsComprehendAdapter = AWSPredictionsService.makeComprehend(
            serviceConfiguration: interpretServiceConfiguration,
            identifier: identifier)

        let awsPollyAdapter = AWSPredictionsService.makePolly(
            serviceConfiguration: convertServiceConfiguration,
            identifier: identifier)

        let transcribeCallbackQueue = DispatchQueue(label: "TranscribeStreamingQueue")

        let transcribeDelegate = NativeWSTranscribeStreamingClientDelegate()

        let awsTranscribeStreamingAdapter = AWSPredictionsService.makeTranscribeStreaming(callbackQueue: transcribeCallbackQueue,
                                                                                          transcribeDelegate: transcribeDelegate,
                                                                                          serviceConfiguration: convertServiceConfiguration,
                                                                                          identifier: identifier)

        self.init(identifier: identifier,
                  awsTranslate: awsTranslateAdapter,
                  awsRekognition: awsRekognitionAdapter,
                  awsTextract: awsTextractAdapter,
                  awsComprehend: awsComprehendAdapter,
                  awsPolly: awsPollyAdapter,
                  awsTranscribeStreaming: awsTranscribeStreamingAdapter,
                  transcribeDelegate: transcribeDelegate,
                  transcribeCallbackQueue: transcribeCallbackQueue,
                  configuration: configuration)

    }

    init(identifier: String,
         awsTranslate: AWSTranslateBehavior,
         awsRekognition: AWSRekognitionBehavior,
         awsTextract: AWSTextractBehavior,
         awsComprehend: AWSComprehendBehavior,
         awsPolly: AWSPollyBehavior,
         awsTranscribeStreaming: AWSTranscribeStreamingBehavior,
         transcribeDelegate: NativeWSTranscribeStreamingClientDelegate,
         transcribeCallbackQueue: DispatchQueue,
         configuration: PredictionsPluginConfiguration) {

        self.identifier = identifier
        self.awsTranslate = awsTranslate
        self.awsRekognition = awsRekognition
        self.awsTextract = awsTextract
        self.awsComprehend = awsComprehend
        self.awsPolly = awsPolly
        self.awsTranscribeStreaming = awsTranscribeStreaming
        self.transcribeDelegate = transcribeDelegate
        self.transcribeCallbackQueue = transcribeCallbackQueue
        self.predictionsConfig = configuration

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

        AWSTranscribeStreaming.remove(forKey: identifier)
        awsTranscribeStreaming = nil

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
            return awsTranscribeStreaming.getTranscribeStreaming()
        case .comprehend:
            return awsComprehend.getComprehend()
        case .textract:
            return awsTextract.getTextract()
        }
    }
    private static func makeAWSTranslate(serviceConfiguration: AmplifyAWSServiceConfiguration,
                                         identifier: String) -> AWSTranslateAdapter {
        AWSTranslate.register(with: serviceConfiguration, forKey: identifier)
        let awsTranslate = AWSTranslate(forKey: identifier)
        return AWSTranslateAdapter(awsTranslate)
    }

    private static func makeRekognition(serviceConfiguration: AmplifyAWSServiceConfiguration,
                                        identifier: String) -> AWSRekognitionAdapter {
        AWSRekognition.register(with: serviceConfiguration, forKey: identifier)
        let awsRekognition = AWSRekognition(forKey: identifier)
        return AWSRekognitionAdapter(awsRekognition)
    }
    private static func makeTextract(serviceConfiguration: AmplifyAWSServiceConfiguration,
                                     identifier: String) -> AWSTextractAdapter {
        AWSTextract.register(with: serviceConfiguration, forKey: identifier)
        let awsTextract = AWSTextract(forKey: identifier)
        return AWSTextractAdapter(awsTextract)
    }
    private static func makePolly(serviceConfiguration: AmplifyAWSServiceConfiguration,
                                  identifier: String) -> AWSPollyAdapter {
        AWSPolly.register(with: serviceConfiguration, forKey: identifier)
        let awsPolly = AWSPolly(forKey: identifier)
        return AWSPollyAdapter(awsPolly)
    }
    private static func makeComprehend(serviceConfiguration: AmplifyAWSServiceConfiguration,
                                       identifier: String) -> AWSComprehendAdapter {
        AWSComprehend.register(with: serviceConfiguration, forKey: identifier)
        let awsComprehend = AWSComprehend(forKey: identifier)
        return AWSComprehendAdapter(awsComprehend)
    }

    private static func makeTranscribeStreaming(callbackQueue: DispatchQueue,
                                                transcribeDelegate: NativeWSTranscribeStreamingClientDelegate,
                                                serviceConfiguration: AmplifyAWSServiceConfiguration,
                                                identifier: String) -> AWSTranscribeStreamingAdapter {
       let webSocketProvider = NativeWebSocketProvider(clientDelegate: transcribeDelegate, callbackQueue: callbackQueue)
        AWSTranscribeStreaming.register(with: serviceConfiguration,
                                        forKey: identifier,
                                        webSocketProvider: webSocketProvider)
        let awsTranscribeStreaming = AWSTranscribeStreaming(forKey: identifier)
        return AWSTranscribeStreamingAdapter(awsTranscribeStreaming)
    }
}

extension AWSPredictionsService: DefaultLogger { }
