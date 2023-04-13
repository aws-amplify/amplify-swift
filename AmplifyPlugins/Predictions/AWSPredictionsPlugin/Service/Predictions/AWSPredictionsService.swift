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
import Foundation
import ClientRuntime
import AWSClientRuntime
//import AWSTranscribeStreaming

class AWSPredictionsService {

    var identifier: String!
    var awsTranslate: AWSTranslateBehavior!
    var awsRekognition: AWSRekognitionBehavior!
    var awsPolly: AWSPollyBehavior!
    var awsComprehend: AWSComprehendBehavior!
    var awsTextract: AWSTextractBehavior!
    var predictionsConfig: PredictionsPluginConfiguration!
    let rekognitionWordLimit = 50

    // TODO: Re-add when complete
//    var awsTranscribeStreaming: AWSTranscribeStreamingBehavior!
//    let nativeWebSocketProvider: NativeWebSocketProvider!
//    let transcribeClientDelegate: NativeWSTranscribeStreamingClientDelegate!

    convenience init(
        configuration: PredictionsPluginConfiguration,
        credentialsProvider: CredentialsProvider,
        identifier: String
    ) throws {


        // MARK: Convert
        let awsTranslateAdapter = AWSPredictionsService.makeAWSTranslate(
            clientConfiguration: try TranslateClient.TranslateClientConfiguration(
                credentialsProvider: credentialsProvider,
                region: configuration.convert.region
            ),
            identifier: identifier
        )

        let awsPollyAdapter = AWSPredictionsService.makePolly(
            clientConfiguration: try PollyClient.PollyClientConfiguration(
                credentialsProvider: credentialsProvider,
                region: configuration.convert.region
            ),
            identifier: identifier
        )


        // MARK: Interpret
        let awsComprehendAdapter = AWSPredictionsService.makeComprehend(
            clientConfiguration: try ComprehendClient.ComprehendClientConfiguration(
                credentialsProvider: credentialsProvider,
                region: configuration.interpret.region
            ),
            identifier: identifier
        )


        // MARK: Identify
        let awsRekognitionAdapter = AWSPredictionsService.makeRekognition(
            clientConfiguration: try RekognitionClient.RekognitionClientConfiguration(
                credentialsProvider: credentialsProvider,
                region: configuration.identify.region
            ),
            identifier: identifier
        )

        let awsTextractAdapter = AWSPredictionsService.makeTextract(
            clientConfiguration: try TextractClient.TextractClientConfiguration(
                credentialsProvider: credentialsProvider,
                region: configuration.identify.region
            ),
            identifier: identifier
        )

        // TODO: Transcribe
//        let transcribeCallbackQueue = DispatchQueue(label: "TranscribeStreamingQueue")
//        let transcribeClientDelegate = NativeWSTranscribeStreamingClientDelegate()
//        let nativeWebSocketProvider = NativeWebSocketProvider(
//            clientDelegate: transcribeClientDelegate,
//            callbackQueue: transcribeCallbackQueue
//        )
//
//        let awsTranscribeStreamingAdapter = AWSPredictionsService.makeTranscribeStreaming(
//            nativeWebSocketProvider: nativeWebSocketProvider,
//            serviceConfiguration: convertServiceConfiguration,
//            identifier: identifier
//        )

        self.init(
            identifier: identifier,
            awsTranslate: awsTranslateAdapter,
            awsRekognition: awsRekognitionAdapter,
            awsTextract: awsTextractAdapter,
            awsComprehend: awsComprehendAdapter,
            awsPolly: awsPollyAdapter,
//            awsTranscribeStreaming: awsTranscribeStreamingAdapter,
//            nativeWebSocketProvider: nativeWebSocketProvider,
//            transcribeClientDelegate: transcribeClientDelegate,
            configuration: configuration
        )

    }

    init(identifier: String,
         awsTranslate: AWSTranslateBehavior,
         awsRekognition: AWSRekognitionBehavior,
         awsTextract: AWSTextractBehavior,
         awsComprehend: AWSComprehendBehavior,
         awsPolly: AWSPollyBehavior,
//         awsTranscribeStreaming: AWSTranscribeStreamingBehavior,
//         nativeWebSocketProvider: NativeWebSocketProvider,
//         transcribeClientDelegate: NativeWSTranscribeStreamingClientDelegate,
         configuration: PredictionsPluginConfiguration) {

        self.identifier = identifier
        self.awsTranslate = awsTranslate
        self.awsRekognition = awsRekognition
        self.awsTextract = awsTextract
        self.awsComprehend = awsComprehend
        self.awsPolly = awsPolly
//        self.awsTranscribeStreaming = awsTranscribeStreaming
//        self.nativeWebSocketProvider = nativeWebSocketProvider
//        self.transcribeClientDelegate = transcribeClientDelegate
        self.predictionsConfig = configuration

    }

    func reset() {
        // TODO: Is there a necessary equivalent in the Swift SDK?
        /*
         AWSTranslate.remove(forKey: identifier)
         AWSRekognition.remove(forKey: identifier)
         AWSTextract.remove(forKey: identifier)
         AWSComprehend.remove(forKey: identifier)
         AWSPolly.remove(forKey: identifier)
         AWSTranscribeStreaming.remove(forKey: identifier)
         */
        awsTranslate = nil
        awsRekognition = nil
        awsTextract = nil
        awsComprehend = nil
        awsPolly = nil

        // TODO: Add back in with streaming
//        awsTranscribeStreaming = nil

        identifier = nil
    }

    // TODO: Re-implement escape hatch since AWSService no longer exists
//    func getEscapeHatch(key: PredictionsAWSService) -> AWSService {
//        switch key {
//        case .rekognition:
//            return awsRekognition.getRekognition()
//        case .translate:
//            return awsTranslate.getTranslate()
//        case .polly:
//            return awsPolly.getPolly()
//            // TODO: Transcribe
////        case .transcribe:
////            return awsTranscribeStreaming.getTranscribeStreaming()
//        case .comprehend:
//            return awsComprehend.getComprehend()
//        case .textract:
//            return awsTextract.getTextract()
//        }
//    }

    private static func makeAWSTranslate(
        clientConfiguration: TranslateClientConfigurationProtocol,
        identifier: String
    ) -> AWSTranslateAdapter {
        let translate = TranslateClient(config: clientConfiguration)
        return AWSTranslateAdapter(translate)
    }

    private static func makeRekognition(
        clientConfiguration: RekognitionClientConfigurationProtocol,
        identifier: String
    ) -> AWSRekognitionAdapter {
        let rekognition = RekognitionClient(config: clientConfiguration)
        return AWSRekognitionAdapter(rekognition)
    }

    private static func makeTextract(
        clientConfiguration: TextractClientConfigurationProtocol,
        identifier: String
    ) -> AWSTextractAdapter {
        let textract = TextractClient(config: clientConfiguration)
        return AWSTextractAdapter(textract)
    }

    private static func makePolly(
        clientConfiguration: PollyClientConfigurationProtocol,
        identifier: String
    ) -> AWSPollyAdapter {
        let polly = PollyClient(config: clientConfiguration)
        return AWSPollyAdapter(polly)
    }
    private static func makeComprehend(
        clientConfiguration: ComprehendClientConfigurationProtocol,
        identifier: String
    ) -> AWSComprehendAdapter {
        let comprehend = ComprehendClient(config: clientConfiguration)
        return AWSComprehendAdapter(comprehend)
    }

    // TODO: Transcribe
//    private static func makeTranscribeStreaming(
//        nativeWebSocketProvider: NativeWebSocketProvider,
//        serviceConfiguration: AmplifyAWSServiceConfiguration,
//        identifier: String
//    ) -> AWSTranscribeStreamingAdapter {
//
//        AWSTranscribeStreaming.register(with: serviceConfiguration,
//                                        forKey: identifier,
//                                        webSocketProvider: nativeWebSocketProvider)
//        let awsTranscribeStreaming = AWSTranscribeStreaming(forKey: identifier)
//        return AWSTranscribeStreamingAdapter(awsTranscribeStreaming)
//    }
}

extension AWSPredictionsService: DefaultLogger { }
