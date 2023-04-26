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
    var awsTranslate: TranslateClientProtocol!
    var awsRekognition: RekognitionClientProtocol!
    var awsPolly: PollyClientProtocol!
    var awsComprehend: ComprehendClientProtocol!
    var awsTextract: TextractClientProtocol!
    var awsTranscribeStreaming: AWSTranscribeStreamingBehavior!
    var predictionsConfig: PredictionsPluginConfiguration!
    let rekognitionWordLimit = 50

    convenience init(
        configuration: PredictionsPluginConfiguration,
        credentialsProvider: CredentialsProvider,
        identifier: String
    ) throws {
        let translateClientConfiguration = try TranslateClient.TranslateClientConfiguration(
            credentialsProvider: credentialsProvider,
            region: configuration.convert.region
        )
        let awsTranslateClient = TranslateClient(config: translateClientConfiguration)

        let pollyClientConfiguration = try PollyClient.PollyClientConfiguration(
            credentialsProvider: credentialsProvider,
            region: configuration.convert.region
        )
        let awsPollyClient = PollyClient(config: pollyClientConfiguration)

        let comprehendClientConfiguration = try ComprehendClient.ComprehendClientConfiguration(
            credentialsProvider: credentialsProvider,
            region: configuration.convert.region
        )
        let awsComprehendClient = ComprehendClient(config: comprehendClientConfiguration)

        let rekognitionClientConfiguration = try RekognitionClient.RekognitionClientConfiguration(
            credentialsProvider: credentialsProvider,
            region: configuration.identify.region
        )
        let awsRekognitionClient = RekognitionClient(config: rekognitionClientConfiguration)

        let textractClientConfiguration = try TextractClient.TextractClientConfiguration(
            credentialsProvider: credentialsProvider,
            region: configuration.identify.region
        )
        let awsTextractClient = TextractClient(config: textractClientConfiguration)

        let awsTranscribeStreamingAdapter = AWSTranscribeStreamingAdapter(
            credentialsProvider: credentialsProvider,
            region: configuration.convert.region
        )

        self.init(
            identifier: identifier,
            awsTranslate: awsTranslateClient,
            awsRekognition: awsRekognitionClient,
            awsTextract: awsTextractClient,
            awsComprehend: awsComprehendClient,
            awsPolly: awsPollyClient,
            awsTranscribeStreaming: awsTranscribeStreamingAdapter,
            configuration: configuration
        )
    }

    init(
        identifier: String,
        awsTranslate: TranslateClientProtocol,
        awsRekognition: RekognitionClientProtocol,
        awsPolly: PollyClientProtocol,
        awsComprehend: ComprehendClientProtocol,
        awsTextract: TextractClientProtocol,
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
}

extension AWSPredictionsService: DefaultLogger {}
