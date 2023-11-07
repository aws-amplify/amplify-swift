//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
@_spi(PluginHTTPClientEngine) import AWSPluginsCore
import Foundation








class AWSPredictionsService {
    var identifier: String!
    var awsTranslate: TranslateClient!
    var awsRekognition: RekognitionClient!
    var awsPolly: PollyClient!
    var awsComprehend: ComprehendClient!
    var awsTextract: TextractClient!
    var awsTranscribeStreaming: AWSTranscribeStreamingBehavior!
    var predictionsConfig: PredictionsPluginConfiguration!
    let rekognitionWordLimit = 50

    convenience init(
        configuration: PredictionsPluginConfiguration,
        credentialsProvider: CredentialsProvider,
        identifier: String
    ) throws {
        let awsTranslateClient = TranslateClient(
            configuration: .init(
                region: configuration.convert.region,
                credentialsProvider: credentialsProvider
            )
        )

        let awsPollyClient = PollyClient(
            configuration: .init(
                region: configuration.convert.region,
                credentialsProvider: credentialsProvider
            )
        )

        let awsComprehendClient = ComprehendClient(
            configuration: .init(
                region: configuration.convert.region,
                credentialsProvider: credentialsProvider
            )
        )

        let awsRekognitionClient = RekognitionClient(
            configuration: .init(
                region: configuration.identify.region,
                credentialsProvider: credentialsProvider
            )
        )

        let awsTextractClient = TextractClient(
            configuration: .init(
                region: configuration.identify.region,
                credentialsProvider: credentialsProvider
            )
        )

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
        awsTranslate: TranslateClient,
        awsRekognition: RekognitionClient,
        awsTextract: TextractClient,
        awsComprehend: ComprehendClient,
        awsPolly: PollyClient,
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
