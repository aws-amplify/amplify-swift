//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
public class StorageGetError: AmplifyError {
    public init(errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion) {
        self.errorDescription = errorDescription
        self.recoverySuggestion = recoverySuggestion
    }
    
    public var errorDescription: ErrorDescription
    
    // specific to the Put operation
    public var recoverySuggestion: RecoverySuggestion
    
    
}
