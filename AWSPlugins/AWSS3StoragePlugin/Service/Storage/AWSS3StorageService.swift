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
    var bucket: String!

    public init() {

    }
}
