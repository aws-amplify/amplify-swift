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
@_spi(PluginHTTPClientEngine) import InternalAmplifyCredentials
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
        credentialsProvider: CredentialsProviding,
        identifier: String
    ) throws {
        let translateClientConfiguration = try TranslateClient.TranslateClientConfiguration(
            region: configuration.convert.region,
            credentialsProvider: credentialsProvider
        )
        translateClientConfiguration.httpClientEngine = .userAgentEngine(
            for: translateClientConfiguration
        )

        let awsTranslateClient = TranslateClient(config: translateClientConfiguration)

        let pollyClientConfiguration = try PollyClient.PollyClientConfiguration(
            region: configuration.convert.region,
            credentialsProvider: credentialsProvider
        )
        pollyClientConfiguration.httpClientEngine = .userAgentEngine(
            for: pollyClientConfiguration
        )
        let awsPollyClient = PollyClient(config: pollyClientConfiguration)

        let comprehendClientConfiguration = try ComprehendClient.ComprehendClientConfiguration(
            region: configuration.convert.region,
            credentialsProvider: credentialsProvider
        )
        comprehendClientConfiguration.httpClientEngine = .userAgentEngine(
            for: comprehendClientConfiguration
        )

        let awsComprehendClient = ComprehendClient(config: comprehendClientConfiguration)

        let rekognitionClientConfiguration = try RekognitionClient.RekognitionClientConfiguration(
            region: configuration.identify.region,
            credentialsProvider: credentialsProvider
        )
        rekognitionClientConfiguration.httpClientEngine = .userAgentEngine(
            for: rekognitionClientConfiguration
        )
        let awsRekognitionClient = RekognitionClient(config: rekognitionClientConfiguration)

        let textractClientConfiguration = try TextractClient.TextractClientConfiguration(
            region: configuration.identify.region,
            credentialsProvider: credentialsProvider
        )
        textractClientConfiguration.httpClientEngine = .userAgentEngine(
            for: textractClientConfiguration
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
        awsTextract: TextractClientProtocol,
        awsComprehend: ComprehendClientProtocol,
        awsPolly: PollyClientProtocol,
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

    func getEscapeHatch<T>(client: PredictionsAWSService<T>) -> T {
        client.fetch(self)
    }
}

extension AWSPredictionsService: DefaultLogger {
    public static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.predictions.displayName, forNamespace: String(describing: self))
    }
    public var log: Logger {
        Self.log
    }
}
