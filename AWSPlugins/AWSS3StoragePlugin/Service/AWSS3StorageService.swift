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

    init(transferUtility: AWSS3TransferUtilityBehavior,
         preSignedURLBuilder: AWSS3PreSignedURLBuilderBehavior,
         awsS3: AWSS3Behavior) {
        self.transferUtility = transferUtility
        self.preSignedURLBuilder = preSignedURLBuilder
        self.awsS3 = awsS3
    }

    init(region: String, mobileClient: AWSMobileClientBehavior, pluginKey: String) throws {
        let serviceConfigurationOptional = AWSServiceConfiguration(region:
            region.aws_regionTypeValue(), credentialsProvider: mobileClient.getCognitoCredentialsProvider())

        guard let serviceConfiguration = serviceConfigurationOptional else {
            throw PluginError.pluginConfigurationError("T##ErrorDescription", "T##RecoverySuggestion")
        }

        // TODO: this is sort of a hack - need to figure out how to deallocate the nsurlsession? in reset?
        let transferUtility = AWSS3TransferUtility.s3TransferUtility(forKey: pluginKey)
        if let transferUtility = transferUtility {
            self.transferUtility = AWSS3TransferUtilityImpl(transferUtility)
        } else {
            AWSS3TransferUtility.register(with: serviceConfiguration, forKey: pluginKey)
            self.transferUtility = AWSS3TransferUtilityImpl(AWSS3TransferUtility.s3TransferUtility(forKey: pluginKey)!)
        }

        AWSS3PreSignedURLBuilder.register(with: serviceConfiguration, forKey: pluginKey)
        AWSS3.register(with: serviceConfiguration, forKey: pluginKey)

        self.preSignedURLBuilder = AWSS3PreSignedURLBuilderImpl(
            AWSS3PreSignedURLBuilder.s3PreSignedURLBuilder(forKey: pluginKey))
        self.awsS3 = AWSS3Impl(AWSS3.s3(forKey: pluginKey))
    }

    func reset() {
        // TODO how to deallocate S3TransferUtility
    }

    func getS3() -> AWSS3 {
        return awsS3.getS3()
    }
}
