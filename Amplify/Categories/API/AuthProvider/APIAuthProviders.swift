//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol APIAuthProviders {
    func oidcAuthProvider() -> AmplifyOIDCAuthProvider?

}

public protocol AmplifyOIDCAuthProvider {
    func getLatestAuthToken() -> Result<String, Error>
}
