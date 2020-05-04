//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public struct AWSAuthDevice: AuthDevice {

    /// Device unique identifier
    public let id: String

    /// Device name
    public let name: String

    /// Device attributes
    public let attributes: [String: String]?

    /// The date this device was created.
    public let createdDate: Date?

    /// The date this device was last authenticated.
    public let lastAuthenticatedDate: Date?

    /// The date this device was last updated.
    public let lastModifiedDate: Date?
}
