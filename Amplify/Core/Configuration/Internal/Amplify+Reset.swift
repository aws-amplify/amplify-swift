//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// swiftlint:disable cyclomatic_complexity
extension Amplify {
    
    /// Resets the state of the Amplify framework.
    ///
    /// Internally, this method:
    /// - Invokes `reset` on each configured category, which clears that category's registered plugins.
    /// - Releases each configured category, and replaces the instances referred to by the static accessor properties
    ///   (e.g., `Amplify.Hub`) with new instances. These instances must subsequently have providers added, and be
    ///   configured prior to use.
    static func reset() async {
        // Looping through all categories to ensure we don't accidentally forget a category at some point in the future
        await withTaskGroup(of: Void.self) { group in
            for categoryType in CategoryType.allCases {
                switch categoryType {
                case .analytics:
                    group.addTask {
                        await Analytics.reset()
                    }
                case .api:
                    group.addTask {
                        await API.reset()
                    }
                case .auth:
                    group.addTask {
                        await Auth.reset()
                    }
                case .dataStore:
                    group.addTask {
                        await DataStore.reset()
                    }
                case .geo:
                    group.addTask {
                        await Geo.reset()
                    }
                case .storage:
                    group.addTask {
                        await Storage.reset()
                    }
                case .predictions:
                    group.addTask {
                        await Predictions.reset()
                    }
                case .hub, .logging:
                    // Hub and Logging should be reset after all other categories
                    break
                }
            }
        }
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await Hub.reset()
            }
            group.addTask {
                await Logging.reset()
            }
        }
        
#if canImport(UIKit)
        devMenu = nil
#endif
        
        // Initialize Logging and Hub first, to ensure their default plugins are registered and available to other
        // categories during their initialization and configuration phases.
        Logging = LoggingCategory()
        Hub = HubCategory()
        
        // Switch over all category types to ensure we don't forget any
        for categoryType in CategoryType.allCases.filter({ $0 != .logging && $0 != .hub }) {
            switch categoryType {
            case .logging, .hub:
                // Initialized above
                break
            case .analytics:
                Analytics = AnalyticsCategory()
            case .api:
                API = AmplifyAPICategory()
            case .auth:
                Auth = AuthCategory()
            case .dataStore:
                DataStore = DataStoreCategory()
            case .geo:
                Geo = GeoCategory()
            case .predictions:
                Predictions = PredictionsCategory()
            case .storage:
                Storage = StorageCategory()
            }
        }
        
        isConfigured = false
    }
}
