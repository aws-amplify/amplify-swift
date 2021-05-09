//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// <#Description#>
public enum AuthProvider {

    case amazon

    case apple

    case facebook

    case google

    case oidc

    case saml

    case custom(String)
}
