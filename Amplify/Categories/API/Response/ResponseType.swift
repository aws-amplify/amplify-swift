//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// Conform to `ResponseType` to specify the type for deserialization.
public protocol ResponseType {

    // The return type for the request
    associatedtype SerializedObject: Decodable
}
