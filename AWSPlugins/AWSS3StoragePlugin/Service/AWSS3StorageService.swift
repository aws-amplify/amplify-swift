//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3
import Amplify
import AWSMobileClient

public class AWSS3StorageService: AWSS3StorageServiceBehaviour {
    var transferUtility: AWSS3TransferUtilityBehavior!
    var preSignedURLBuilder: AWSS3PreSignedURLBuilderBehavior!
    var awsS3: AWSS3Behavior!
    var identifier: String!

    public init() {

    }

    func configure(region: AWSRegionType,
                   cognitoCredentialsProvider: AWSCognitoCredentialsProvider,
                   identifier: String) throws {
        let serviceConfigurationOptional = AWSServiceConfiguration(region: region,
                                                                   credentialsProvider: cognitoCredentialsProvider)

        guard let serviceConfiguration = serviceConfigurationOptional else {
            throw PluginError.pluginConfigurationError("T##ErrorDescription", "T##RecoverySuggestion")
        }

        AWSS3TransferUtility.register(with: serviceConfiguration, forKey: identifier)
        AWSS3PreSignedURLBuilder.register(with: serviceConfiguration, forKey: identifier)
        AWSS3.register(with: serviceConfiguration, forKey: identifier)

        let transferUtilityOptional = AWSS3TransferUtility.s3TransferUtility(forKey: identifier)
        guard let transferUtility = transferUtilityOptional else {
            throw PluginError.pluginConfigurationError("fail to create transferUtiltiy", "failed")
        }

        let preSignedURLBuilder = AWSS3PreSignedURLBuilderImpl(
            AWSS3PreSignedURLBuilder.s3PreSignedURLBuilder(forKey: identifier))
        let awsS3 = AWSS3Impl(AWSS3.s3(forKey: identifier))

        configure(transferUtility: AWSS3TransferUtilityImpl(transferUtility),
                  preSignedURLBuilder: preSignedURLBuilder,
                  awsS3: awsS3,
                  identifier: identifier)
    }

    func configure(transferUtility: AWSS3TransferUtilityBehavior,
                   preSignedURLBuilder: AWSS3PreSignedURLBuilderBehavior,
                   awsS3: AWSS3Behavior,
                   identifier: String) {
        self.transferUtility = transferUtility
        self.preSignedURLBuilder = preSignedURLBuilder
        self.awsS3 = awsS3
        self.identifier = identifier
    }

    func reset() {
        AWSS3TransferUtility.remove(forKey: identifier)
        AWSS3PreSignedURLBuilder.remove(forKey: identifier)
        AWSS3.remove(forKey: identifier)
    }

    func getEscapeHatch() -> AWSS3 {
        return awsS3.getS3()
    }
}
