//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSS3

protocol AWSS3StorageServiceBehaviour {
    func configure(region: AWSRegionType,
                   cognitoCredentialsProvider: AWSCognitoCredentialsProvider,
                   identifier: String) throws

    func reset()

    func getEscapeHatch() -> AWSS3

    func execute(_ request: AWSS3StorageGetRequest, identityId: String, onEvent:
        @escaping (StorageEvent<StorageOperationReference, Progress, StorageGetResult, StorageGetError>) -> Void)

    func execute(_ request: AWSS3StoragePutRequest, identityId: String, onEvent:
        @escaping (StorageEvent<StorageOperationReference, Progress, StoragePutResult, StoragePutError>) -> Void)

    func execute(_ request: AWSS3StorageListRequest, identityId: String, onEvent:
        @escaping (StorageEvent<Void, Void, StorageListResult, StorageListError>) -> Void)

    func execute(_ request: AWSS3StorageRemoveRequest, identityId: String, onEvent:
        @escaping (StorageEvent<Void, Void, StorageRemoveResult, StorageRemoveError>) -> Void)
}
