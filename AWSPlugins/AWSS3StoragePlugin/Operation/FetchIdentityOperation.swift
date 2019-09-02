//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSMobileClient

public class FetchIdentityOperation: AsynchronousOperation {

    var identity: NSString?
    //  TODO: most likely, create generic class to contain StorageErrors
    // and translate it back to the error we want to return
    var storageError: StorageGetError?

    override public func main() {
        let authContinuationBlock = { (task: AWSTask<NSString>) -> Any? in
            if let error = task.error as? AWSMobileClientError {
                self.storageError = StorageGetError.unknown("No Identitiy", "no identity!")
            } else if let identity = task.result {
                self.identity = identity
            } else {
                self.storageError = StorageGetError.unknown("No Identitiy!!!", "no identity!!!!")
            }

            self.finish()
            return nil
        }

        AWSMobileClient.sharedInstance().getIdentityId().continueWith(block: authContinuationBlock)
    }
}
