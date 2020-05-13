//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSMobileClient

public enum AWSAuthService {

    case awsMobileClient(AWSMobileClient)

    // Below cases are for future, currently the auth plugin only uses AWSMobileClient.
    case cognitoUserPoolService

    case cognitoIdentityPoolService
}
