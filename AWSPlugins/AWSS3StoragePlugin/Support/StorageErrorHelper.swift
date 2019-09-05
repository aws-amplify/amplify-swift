//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSMobileClient
import Amplify

public class StorageErrorHelper {
    public static func getInnerMessage(_ error: NSError) -> String {
        return error.localizedDescription // TODO: generate useful inner message
    }

    public static func getErrorDescription(innerMessage: String) -> String {
        return "The error is [" + innerMessage + "]"
    }
}
