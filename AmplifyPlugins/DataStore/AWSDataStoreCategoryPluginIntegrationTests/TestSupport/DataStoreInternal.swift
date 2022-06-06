//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@testable import AWSDataStoreCategoryPlugin

struct DataStoreInternal {

    static var dbFilePath: URL? { getAdapter()?.dbFilePath }

    static func getRemoteSyncEngine() -> RemoteSyncEngineBehavior? {
        if #available(iOS 13.0, *) {
            if let dataStorePlugin = tryGetPlugin(),
               let storageEngine = dataStorePlugin.storageEngine as? StorageEngine,
               let syncEngine = storageEngine.syncEngine {
                return syncEngine
            }
        }

        return nil
    }

    static func getAdapter() -> SQLiteStorageEngineAdapter? {
        if let dataStorePlugin = tryGetPlugin(),
           let storageEngine = dataStorePlugin.storageEngine as? StorageEngine,
           let adapter = storageEngine.storageAdapter as? SQLiteStorageEngineAdapter {
            return adapter
        }
        return nil
    }

    static func tryGetPlugin() -> AWSDataStorePlugin? {
        do {
            return try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as? AWSDataStorePlugin
        } catch {
            return nil
        }
    }
}
