//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum AWSAuthorizationConfiguration {
    case none
    case apiKey(APIKeyConfiguration)
    case awsIAM(AWSIAMConfiguration)
    case openIDConnect(OIDCConfiguration)
    case amazonCognitoUserPools(CognitoUserPoolsConfiguration)
}
