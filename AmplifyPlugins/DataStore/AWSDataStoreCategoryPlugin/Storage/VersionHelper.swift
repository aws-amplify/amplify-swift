//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum ActionTaken {
    case DatabaseFirstTimeCreation
    case VersionUnchanged
    case DataBaseDeleteAndVersionUpdated
}

class VersionHelper {
    static func deleteDBIfRequired(versionStorage: UserDefaults = UserDefaults.standard,
                                   newVersion: String,
                                   fileManager: FileManager = FileManager.default,
                                   dbFilePath: URL) -> Result<ActionTaken, Error> {
        let oldVersion = versionStorage.string(forKey: "Version")

        // if versionStorage does not contain version, update incomingVersion and return
        guard oldVersion != nil else {
            return .success(.DatabaseFirstTimeCreation)
        }

        // if versionStorage contains version, check if incoming version is different
        if oldVersion != newVersion {
            let fileManager = FileManager.default
            do {
                try fileManager.removeItem(at: dbFilePath)
                StorageEngine.log.verbose("Warning: Recreating database, your previous database will be deleted")
                return .success(.DataBaseDeleteAndVersionUpdated)
            } catch {
                StorageEngine.log.error("Failed to delete database file located at: \(dbFilePath), error: \(error)")
                return .failure(error)
            }
        }

        // if version unchanged
        return .success(.VersionUnchanged)
    }
}
