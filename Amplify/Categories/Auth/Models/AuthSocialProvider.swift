//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
// TODO: Rename when this issue is solved - https://github.com/aws-amplify/amplify-ios/issues/426
public enum AuthNProvider {

    case amazon

    case apple

    case facebook

    case google

    case oidc

    case saml

    case custom(String)
}
