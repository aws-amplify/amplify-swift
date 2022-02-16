//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/*
import Foundation
import AWSS3
import Amplify
import AWSPluginsCore

class AWSS3StorageService: AWSS3StorageServiceBehaviour {

    var transferUtility: AWSS3TransferUtilityBehavior!
    var preSignedURLBuilder: AWSS3PreSignedURLBuilderBehavior!
    var awsS3: AWSS3Behavior!
    var identifier: String!
    var bucket: String!

    convenience init(region: AWSRegionType,
                     bucket: String,
                     credentialsProvider: AWSCredentialsProvider,
                     identifier: String) throws {
        let serviceConfiguration = AmplifyAWSServiceConfiguration(region: region,
                                                                  credentialsProvider: credentialsProvider)

        AWSS3TransferUtility.register(with: serviceConfiguration, forKey: identifier)
        AWSS3PreSignedURLBuilder.register(with: serviceConfiguration, forKey: identifier)
        AWSS3.register(with: serviceConfiguration, forKey: identifier)

        let transferUtilityOptional = AWSS3TransferUtility.s3TransferUtility(forKey: identifier)
        guard let transferUtility = transferUtilityOptional else {
            throw PluginError.pluginConfigurationError(
                PluginErrorConstants.transferUtilityInitializationError.errorDescription,
                PluginErrorConstants.transferUtilityInitializationError.recoverySuggestion)
        }

        let preSignedURLBuilder = AWSS3PreSignedURLBuilderAdapter(
            AWSS3PreSignedURLBuilder.s3PreSignedURLBuilder(forKey: identifier))
        let awsS3 = AWSS3Adapter(AWSS3.s3(forKey: identifier))

        self.init(transferUtility: AWSS3TransferUtilityAdapter(transferUtility),
                  preSignedURLBuilder: preSignedURLBuilder,
                  awsS3: awsS3,
                  bucket: bucket,
                  identifier: identifier)
    }

    init(transferUtility: AWSS3TransferUtilityBehavior,
         preSignedURLBuilder: AWSS3PreSignedURLBuilderBehavior,
         awsS3: AWSS3Behavior,
         bucket: String,
         identifier: String) {
        self.transferUtility = transferUtility
        self.preSignedURLBuilder = preSignedURLBuilder
        self.awsS3 = awsS3
        self.bucket = bucket
        self.identifier = identifier
    }

    func reset() {
        AWSS3TransferUtility.remove(forKey: identifier)
        transferUtility = nil
        AWSS3PreSignedURLBuilder.remove(forKey: identifier)
        preSignedURLBuilder = nil
        AWSS3.remove(forKey: identifier)
        awsS3 = nil
        bucket = nil
        identifier = nil
    }
}
*/
