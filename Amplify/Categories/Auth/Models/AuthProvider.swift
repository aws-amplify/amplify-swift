//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum AuthProvider {

    case amazon

    case apple

    case facebook

    case google

    case oidc

    case saml

    case custom(String)
}
