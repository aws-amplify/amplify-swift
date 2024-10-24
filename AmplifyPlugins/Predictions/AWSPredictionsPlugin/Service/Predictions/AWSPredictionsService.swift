//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol Amplify.Logger
import Amplify
import AWSRekognition
import AWSTranslate
import AWSTextract
import AWSComprehend
import AWSPolly
import AWSPluginsCore
@_spi(PluginHTTPClientEngine) import InternalAmplifyCredentials
import Foundation
import AwsCommonRuntimeKit
import AWSTranscribeStreaming
import SmithyIdentity

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
        credentialIdentityResolver: any AWSCredentialIdentityResolver,
        identifier: String
    ) throws {
        let translateClientConfiguration = try TranslateClient.TranslateClientConfiguration(
            awsCredentialIdentityResolver: credentialIdentityResolver,
            region: configuration.convert.region,
            signingRegion: configuration.convert.region
        )
        translateClientConfiguration.httpClientEngine = .userAgentEngine(
            for: translateClientConfiguration
        )

        let awsTranslateClient = TranslateClient(config: translateClientConfiguration)

        let pollyClientConfiguration = try PollyClient.PollyClientConfiguration(
            awsCredentialIdentityResolver: credentialIdentityResolver,
            region: configuration.convert.region,
            signingRegion: configuration.convert.region
        )
        pollyClientConfiguration.httpClientEngine = .userAgentEngine(
            for: pollyClientConfiguration
        )
        let awsPollyClient = PollyClient(config: pollyClientConfiguration)

        let comprehendClientConfiguration = try ComprehendClient.ComprehendClientConfiguration(
            awsCredentialIdentityResolver: credentialIdentityResolver,
            region: configuration.convert.region,
            signingRegion: configuration.convert.region
        )
        comprehendClientConfiguration.httpClientEngine = .userAgentEngine(
            for: comprehendClientConfiguration
        )

        let awsComprehendClient = ComprehendClient(config: comprehendClientConfiguration)

        let rekognitionClientConfiguration = try RekognitionClient.RekognitionClientConfiguration(
            awsCredentialIdentityResolver: credentialIdentityResolver,
            region: configuration.identify.region,
            signingRegion: configuration.convert.region
        )
        rekognitionClientConfiguration.httpClientEngine = .userAgentEngine(
            for: rekognitionClientConfiguration
        )
        let awsRekognitionClient = RekognitionClient(config: rekognitionClientConfiguration)

        let textractClientConfiguration = try TextractClient.TextractClientConfiguration(
            awsCredentialIdentityResolver: credentialIdentityResolver,
            region: configuration.identify.region,
            signingRegion: configuration.convert.region
        )
        textractClientConfiguration.httpClientEngine = .userAgentEngine(
            for: textractClientConfiguration
        )
        let awsTextractClient = TextractClient(config: textractClientConfiguration)

        let awsTranscribeStreamingAdapter = AWSTranscribeStreamingAdapter(
            credentialIdentityResolver: credentialIdentityResolver,
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
