//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

/// Error Handler function typealias
public typealias DataStoreErrorHandler = (AmplifyError) -> Void

/// Holds a reference to both the local `Model` and the remote one during a conflict
/// resolution. Implementations of the `DataStoreConflictHandler` use this to decide
/// what the outcome of a conflict should be.
public struct DataStoreConclictData {
    public let local: Model
    public let remote: Model
}

/// Conflict Handler function typealias. The function is used during a conflict that
/// could not be resolved and requires a decision from the consumer.
public typealias DataStoreConflictHandler = (DataStoreConclictData, DataStoreConflictHandlerResolver) -> Void

/// Callback for the `DataStoreConflictHandler`.
public typealias DataStoreConflictHandlerResolver = (DataStoreConflictHandlerResult) -> Void

/// The conflict resolution result enum.
public enum DataStoreConflictHandlerResult {
    
    /// Discard the local changes in favor of the remote ones.
    case discard
    
    /// Keep the local changes.
    case keep
    
    /// Return a new `Model` instance that should used instead of the local and remote changes.
    case new(Model)
}


/// The `DataStore` plugin configuration object.
public struct DataStoreConfiguration {

    public let errorHandler: DataStoreErrorHandler
    public let conflictHandler: DataStoreConflictHandler
    public let syncInterval: UInt
    public let syncMaxRecords: UInt
    public let syncPageSize: UInt

    init(errorHandler: @escaping DataStoreErrorHandler,
         conflictHandler: @escaping DataStoreConflictHandler,
         syncInterval: UInt,
         syncMaxRecords: UInt,
         syncPageSize: UInt) {
        self.errorHandler = errorHandler
        self.conflictHandler = conflictHandler
        self.syncInterval = syncInterval
        self.syncMaxRecords = syncMaxRecords
        self.syncPageSize = syncPageSize
    }

}

extension DataStoreConfiguration {

    public static let defaultSyncInterval: UInt = 1_440
    public static let defaultSyncMaxRecords: UInt = 10_000
    public static let defaultSyncPageSize: UInt = 1_000

    /// Creates a custom configuration. The only required property is `conflictHandler`.
    ///
    /// - Parameters:
    ///   - errorHandler: a callback function called on unhandled errors
    ///   - conflictHandler: a callback called when a conflict could not be resolved by the service
    ///   - syncInterval: how often the sync engine will run
    ///   - syncMaxRecords: the number of records to sync per execution
    ///   - syncPageSize: the page size of each sync execution
    /// - Returns: an instance of `DataStoreConfiguration` with the passed parameters.
    public static func custom(
        errorHandler: @escaping DataStoreErrorHandler = { error in
            Amplify.Logging.error(error: error)
        },
        conflictHandler: @escaping DataStoreConflictHandler,
        syncInterval: UInt = DataStoreConfiguration.defaultSyncInterval,
        syncMaxRecords: UInt = DataStoreConfiguration.defaultSyncMaxRecords,
        syncPageSize: UInt = DataStoreConfiguration.defaultSyncPageSize
    ) -> DataStoreConfiguration {
        return DataStoreConfiguration(errorHandler: errorHandler,
                                      conflictHandler: conflictHandler,
                                      syncInterval: syncInterval,
                                      syncMaxRecords: syncMaxRecords,
                                      syncPageSize: syncPageSize)
    }

    /// The default configuration.
    public static var `default`: DataStoreConfiguration {
        .custom(conflictHandler: { _, resolver  in
            resolver(.discard)
        })
    }

}
