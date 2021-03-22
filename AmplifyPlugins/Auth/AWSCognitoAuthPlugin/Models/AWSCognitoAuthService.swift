//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if COCOAPODS
import AWSMobileClient
#else
import AWSMobileClientXCF
#endif

public enum AWSCognitoAuthService {

    case awsMobileClient(AWSMobileClient)

}
