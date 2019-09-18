//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
public enum StorageGetDestination {
    // download to memory
    case data

    // local - local file path to download to
    case file(local: URL)

    // expires - when remote url will expire
    case url(expires: Int?)
}
