//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@testable import AWSPluginsCore
@testable import AWSS3StoragePlugin
import Foundation

extension AWSS3StorageDownloadFileOperation {
    convenience init(
        _ request: StorageDownloadFileRequest,
        storageConfiguration: AWSS3StoragePluginConfiguration,
        storageService: AWSS3StorageServiceBehavior,
        authService: AWSAuthServiceBehavior,
        progressListener: InProcessListener? = nil,
        resultListener: ResultListener? = nil
    ) {
        self.init(
            request,
            storageConfiguration: storageConfiguration,
            storageServiceProvider: {
                return storageService
            },
            authService: authService,
            progressListener: progressListener,
            resultListener: resultListener
        )
    }
}

extension AWSS3StorageDownloadDataOperation {
    convenience init(
        _ request: StorageDownloadDataRequest,
        storageConfiguration: AWSS3StoragePluginConfiguration,
        storageService: AWSS3StorageServiceBehavior,
        authService: AWSAuthServiceBehavior,
        progressListener: InProcessListener? = nil,
        resultListener: ResultListener? = nil
    ) {
        self.init(
            request,
            storageConfiguration: storageConfiguration,
            storageServiceProvider: {
                return storageService
            },
            authService: authService,
            progressListener: progressListener,
            resultListener: resultListener
        )
    }
}

extension AWSS3StorageUploadDataOperation {
    convenience init(
        _ request: StorageUploadDataRequest,
        storageConfiguration: AWSS3StoragePluginConfiguration,
        storageService: AWSS3StorageServiceBehavior,
        authService: AWSAuthServiceBehavior,
        progressListener: InProcessListener? = nil,
        resultListener: ResultListener? = nil
    ) {
        self.init(
            request,
            storageConfiguration: storageConfiguration,
            storageServiceProvider: {
                return storageService
            },
            authService: authService,
            progressListener: progressListener,
            resultListener: resultListener
        )
    }
}

extension AWSS3StorageUploadFileOperation {
    convenience init(
        _ request: StorageUploadFileRequest,
        storageConfiguration: AWSS3StoragePluginConfiguration,
        storageService: AWSS3StorageServiceBehavior,
        authService: AWSAuthServiceBehavior,
        progressListener: InProcessListener? = nil,
        resultListener: ResultListener? = nil
    ) {
        self.init(
            request,
            storageConfiguration: storageConfiguration,
            storageServiceProvider: {
                return storageService
            },
            authService: authService,
            progressListener: progressListener,
            resultListener: resultListener
        )
    }
}
