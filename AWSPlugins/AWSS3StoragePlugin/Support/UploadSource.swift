//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
public enum UploadSource {
    // local - local file path to upload from
    case file(file: URL)

    // expires - when remote url will expire
    case data(data: Data)
}
