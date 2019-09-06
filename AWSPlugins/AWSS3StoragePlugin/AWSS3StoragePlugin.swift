//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSS3
import AWSMobileClient

public class AWSS3StoragePlugin: StorageCategoryPlugin {

    private static let AWSS3StoragePluginKey = "AWSS3StoragePlugin"

    // TODO move this variable somewhere else into constant file
    private static let AWSS3StoragePluginNotConfiguredError = """
        AWSS3StoragePlugin not configured.
        Call Amplify.configure() to configure. This could happen if Amplify.reset().
        """

    private var bucket: String!
    private var storageService: AWSS3StorageServiceBehaviour!
    private var authService: AWSAuthServiceBehavior!
    private var queue: OperationQueue!
    private var defaultAccessLevel: StorageAccessLevel!

    public var key: PluginKey {
        return AWSS3StoragePlugin.AWSS3StoragePluginKey
    }

    public init() {
    }

    public func configure(using configuration: Any) throws {
        if let configuration = configuration as? [String: Any] {
            guard let bucket = configuration["Bucket"] as? String else {
                throw PluginError.pluginConfigurationError("Bucket not in configuration",
                                                           "Bucket should be in the configuration")
            }

            if bucket.isEmpty {
                throw PluginError.pluginConfigurationError("Bucket is empty in configuration",
                                                           "Bucket should not be empty in the configuration")
            }

            guard let region = configuration["Region"] as? String else {
                throw PluginError.pluginConfigurationError("Region not in configuration",
                                                           "Region should be in the configuration")
            }

            if region.isEmpty {
                throw PluginError.pluginConfigurationError("Region should not be empty in configuration",
                                                           "Region should not be empty in the configuration")
            }

            // TODO what if we cannot get regionTypeValue() ?? validation here.
            let regionType = region.aws_regionTypeValue()

            let authService = AWSAuthService()
            authService.configure()

            let storageService = AWSS3StorageService()
            try storageService.configure(region: regionType,
                                         bucket: bucket,
                                         cognitoCredentialsProvider: authService.getCognitoCredentialsProvider(),
                                         identifier: key)

            configure(bucket: bucket, storageService: storageService, authService: authService)
        }
    }

    func configure(bucket: String,
                   storageService: AWSS3StorageServiceBehaviour,
                   authService: AWSAuthServiceBehavior,
                   queue: OperationQueue = OperationQueue(),
                   defaultAccessLevel: StorageAccessLevel = .public) {
        self.bucket = bucket
        self.storageService = storageService
        self.authService = authService
        self.queue = queue
        self.defaultAccessLevel = defaultAccessLevel
    }

    public func reset() {
        bucket = nil
        storageService.reset()
        storageService = nil
        authService.reset()
        authService = nil
        queue = nil
    }

    public func get(key: String,
                    options: StorageGetOption?,
                    onEvent: StorageGetEvent?) -> StorageGetOperation {

        let storageGetDestination = options?.storageGetDestination ?? .url(expires: nil)
        let request = AWSS3StorageGetRequest(accessLevel: options?.accessLevel ?? defaultAccessLevel,
                                             targetIdentityId: options?.targetIdentityId,
                                             key: key,
                                             storageGetDestination: storageGetDestination,
                                             options: options?.options)

        let getOperation = AWSS3StorageGetOperation(request,
                                                    storageService: storageService,
                                                    authService: authService,
                                                    onEvent: onEvent)

        queue.addOperation(getOperation)
        return getOperation
    }

    public func put(key: String,
                    data: Data,
                    options: StoragePutOption?,
                    onEvent: StoragePutEvent?) -> StoragePutOperation {

        let request = AWSS3StoragePutRequest(accessLevel: options?.accessLevel ?? defaultAccessLevel,
                                             key: key,
                                             uploadSource: .data(data: data),
                                             contentType: options?.contentType,
                                             metadata: options?.metadata,
                                             options: options?.options)

        return put(request, onEvent: onEvent)
    }

    public func put(key: String,
                    local: URL,
                    options: StoragePutOption?,
                    onEvent: StoragePutEvent?) -> StoragePutOperation {

        let request = AWSS3StoragePutRequest(accessLevel: options?.accessLevel ?? defaultAccessLevel,
                                             key: key,
                                             uploadSource: .file(file: local),
                                             contentType: options?.contentType,
                                             metadata: options?.metadata,
                                             options: options?.options)

        return put(request, onEvent: onEvent)
    }

    public func remove(key: String,
                       options: StorageRemoveOption?,
                       onEvent: StorageRemoveEvent?) -> StorageRemoveOperation {
        let request = AWSS3StorageRemoveRequest(accessLevel: options?.accessLevel ?? defaultAccessLevel,
                                                key: key)
        let removeOperation = AWSS3StorageRemoveOperation(request,
                                                          storageService: storageService,
                                                          authService: authService,
                                                          onEvent: onEvent)
        queue.addOperation(removeOperation)

        return removeOperation
    }

    public func list(options: StorageListOption?, onEvent: StorageListEvent?) -> StorageListOperation {
        let request = AWSS3StorageListRequest(accessLevel: options?.accessLevel ?? defaultAccessLevel,
                                              prefix: options?.prefix,
                                              limit: options?.limit)
        let listOperation = AWSS3StorageListOperation(request,
                                                      storageService: storageService,
                                                      authService: authService,
                                                      onEvent: onEvent)
        queue.addOperation(listOperation)

        return listOperation
    }

    public func stub() {
    }

    private func put(_ request: AWSS3StoragePutRequest, onEvent: StoragePutEvent?) -> StoragePutOperation {

        let putOperation = AWSS3StoragePutOperation(request,
                                                    storageService: storageService,
                                                    authService: authService,
                                                    onEvent: onEvent)
        queue.addOperation(putOperation)

        return putOperation
    }

    public func getEscapeHatch() -> AWSS3 {
        return storageService.getEscapeHatch()
    }
}
