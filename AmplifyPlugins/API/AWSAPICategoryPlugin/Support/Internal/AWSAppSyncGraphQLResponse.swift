//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

/// The raw response coming back from the AppSync GraphQL service
struct AWSAppSyncGraphQLResponse {
    let data: [String: JSONValue]?
    let errors: [JSONValue]?
}
