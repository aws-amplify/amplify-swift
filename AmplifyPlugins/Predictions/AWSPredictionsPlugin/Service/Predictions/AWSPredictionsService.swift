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
import AWSTranscribeStreaming

class AWSPredictionsService {
    var identifier: String!
    var awsTranslate: AWSTranslateBehavior!
    var awsRekognition: AWSRekognitionBehavior!
    var awsPolly: AWSPollyBehavior!
    var awsComprehend: AWSComprehendBehavior!
    var awsTextract: AWSTextractBehavior!
    var awsTranscribeStreaming: AWSTranscribeStreamingBehavior!
    var predictionsConfig: PredictionsPluginConfiguration!
    let rekognitionWordLimit = 50

    convenience init(
        configuration: PredictionsPluginConfiguration,
        credentialsProvider: CredentialsProvider,
        identifier: String
    ) throws {
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

        let awsComprehendAdapter = AWSPredictionsService.makeComprehend(
            clientConfiguration: try ComprehendClient.ComprehendClientConfiguration(
                credentialsProvider: credentialsProvider,
                region: configuration.interpret.region
            ),
            identifier: identifier
        )

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

        let awsTranscribeStreamingAdapter = AWSTranscribeStreamingAdapter()

        self.init(
            identifier: identifier,
            awsTranslate: awsTranslateAdapter,
            awsRekognition: awsRekognitionAdapter,
            awsTextract: awsTextractAdapter,
            awsComprehend: awsComprehendAdapter,
            awsPolly: awsPollyAdapter,
            awsTranscribeStreaming: awsTranscribeStreamingAdapter,
            configuration: configuration
        )

    }

    init(identifier: String,
         awsTranslate: AWSTranslateBehavior,
         awsRekognition: AWSRekognitionBehavior,
         awsTextract: AWSTextractBehavior,
         awsComprehend: AWSComprehendBehavior,
         awsPolly: AWSPollyBehavior,
         awsTranscribeStreaming: AWSTranscribeStreamingBehavior,
         configuration: PredictionsPluginConfiguration
    ) {

        self.identifier = identifier
        self.awsTranslate = awsTranslate
        self.awsRekognition = awsRekognition
        self.awsTextract = awsTextract
        self.awsComprehend = awsComprehend
        self.awsPolly = awsPolly
        self.awsTranscribeStreaming = awsTranscribeStreaming
        self.predictionsConfig = configuration

    }

    func reset() {
        awsTranslate = nil
        awsRekognition = nil
        awsTextract = nil
        awsComprehend = nil
        awsPolly = nil
        awsTranscribeStreaming = nil
        identifier = nil
    }

    func getEscapeHatch<T>(client: PredictionsAWSService<T>) -> T {
        client.fetch(self)
    }

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
}

extension AWSPredictionsService: DefaultLogger {}
