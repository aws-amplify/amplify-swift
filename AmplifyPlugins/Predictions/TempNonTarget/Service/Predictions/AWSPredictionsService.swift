//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
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
    let nativeWebSocketProvider: NativeWebSocketProvider!
    let transcribeClientDelegate: NativeWSTranscribeStreamingClientDelegate!

    convenience init(configuration: PredictionsPluginConfiguration,
                     credentialsProvider: AWSCredentialsProvider,
                     identifier: String) throws {

        let interpretServiceConfiguration = AmplifyAWSServiceConfiguration(region: configuration.interpret.region,
                                                                           credentialsProvider: credentialsProvider)
        let identifyServiceConfiguration = AmplifyAWSServiceConfiguration(region: configuration.identify.region,
                                                                          credentialsProvider: credentialsProvider)
        let convertServiceConfiguration =  AmplifyAWSServiceConfiguration(region: configuration.convert.region,
                                                                          credentialsProvider: credentialsProvider)

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

        let transcribeClientDelegate = NativeWSTranscribeStreamingClientDelegate()

        let nativeWebSocketProvider = NativeWebSocketProvider(
            clientDelegate: transcribeClientDelegate,
            callbackQueue: transcribeCallbackQueue
        )

        let awsTranscribeStreamingAdapter = AWSPredictionsService.makeTranscribeStreaming(
            nativeWebSocketProvider: nativeWebSocketProvider,
            serviceConfiguration: convertServiceConfiguration,
            identifier: identifier
        )

        self.init(identifier: identifier,
                  awsTranslate: awsTranslateAdapter,
                  awsRekognition: awsRekognitionAdapter,
                  awsTextract: awsTextractAdapter,
                  awsComprehend: awsComprehendAdapter,
                  awsPolly: awsPollyAdapter,
                  awsTranscribeStreaming: awsTranscribeStreamingAdapter,
                  nativeWebSocketProvider: nativeWebSocketProvider,
                  transcribeClientDelegate: transcribeClientDelegate,
                  configuration: configuration)

    }

    init(identifier: String,
         awsTranslate: AWSTranslateBehavior,
         awsRekognition: AWSRekognitionBehavior,
         awsTextract: AWSTextractBehavior,
         awsComprehend: AWSComprehendBehavior,
         awsPolly: AWSPollyBehavior,
         awsTranscribeStreaming: AWSTranscribeStreamingBehavior,
         nativeWebSocketProvider: NativeWebSocketProvider,
         transcribeClientDelegate: NativeWSTranscribeStreamingClientDelegate,
         configuration: PredictionsPluginConfiguration) {

        self.identifier = identifier
        self.awsTranslate = awsTranslate
        self.awsRekognition = awsRekognition
        self.awsTextract = awsTextract
        self.awsComprehend = awsComprehend
        self.awsPolly = awsPolly
        self.awsTranscribeStreaming = awsTranscribeStreaming
        self.nativeWebSocketProvider = nativeWebSocketProvider
        self.transcribeClientDelegate = transcribeClientDelegate
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

    private static func makeTranscribeStreaming(nativeWebSocketProvider: NativeWebSocketProvider,
                                                serviceConfiguration: AmplifyAWSServiceConfiguration,
                                                identifier: String) -> AWSTranscribeStreamingAdapter {

        AWSTranscribeStreaming.register(with: serviceConfiguration,
                                        forKey: identifier,
                                        webSocketProvider: nativeWebSocketProvider)
        let awsTranscribeStreaming = AWSTranscribeStreaming(forKey: identifier)
        return AWSTranscribeStreamingAdapter(awsTranscribeStreaming)
    }
}

extension AWSPredictionsService: DefaultLogger { }
