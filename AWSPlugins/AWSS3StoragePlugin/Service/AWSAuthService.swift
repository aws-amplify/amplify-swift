//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSMobileClient
import AWSS3

public class AWSAuthService: AWSAuthServiceBehavior {

    var mobileClient: AWSMobileClientBehavior!

    public init() {
    }

    func configure() {
        configure(mobileClient: AWSMobileClientImpl(AWSMobileClient.sharedInstance()))
    }

    func configure(mobileClient: AWSMobileClientBehavior) {
        self.mobileClient = mobileClient
    }

    func reset() {
        self.mobileClient = nil
    }

    func getCognitoCredentialsProvider() -> AWSCognitoCredentialsProvider {
        return mobileClient.getCognitoCredentialsProvider()
    }

    func getIdentityId() -> Result<String, StorageError> {
        let task = mobileClient.getIdentityId()
        task.waitUntilFinished()

        guard task.error == nil else {
            if let error = task.error! as? AWSMobileClientError {
                return .failure(map(error))
            }

            return .failure(StorageError.identity("Could not determine error", "no identity!"))
        }

        guard let identityId = task.result else {
            let error = StorageError.identity("No Identity", "no identity!")
            return .failure(error)
        }

        return .success(identityId as String)
    }

    private func map(_ error: AWSMobileClientError) -> StorageError {
        switch error {
        case .identityIdUnavailable(let message):
            return StorageError.identity(message, error.localizedDescription)
        case .guestAccessNotAllowed(let message):
            return StorageError.identity(message, error.localizedDescription)
        default:
            return StorageError.identity(error.localizedDescription, "")
        }
    }
}
