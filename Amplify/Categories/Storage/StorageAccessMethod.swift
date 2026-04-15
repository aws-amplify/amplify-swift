//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The HTTP method for pre-signed URL generation in Storage operations.
///
/// - Tag: StorageAccessMethod
public enum StorageAccessMethod {

    /// Generate a pre-signed URL for downloading (GET)
    ///
    /// - Tag: StorageAccessMethod.get
    case get

    /// Generate a pre-signed URL for uploading (PUT)
    ///
    /// - Tag: StorageAccessMethod.put
    case put
}
