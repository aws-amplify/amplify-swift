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
    /// - Invokes `reset` on each configured category, which clears that categories registered plugins.
    /// - Releases each configured category, and replaces the instances referred to by the static accessor properties
    ///   (e.g., `Amplify.Hub`) with new instances. These instances must subsequently have providers added, and be
    ///   configured prior to use.
    static func reset() {
        // Looping through all categories to ensure we don't accidentally forget a category at some point in the future

        let group = DispatchGroup()

        for categoryType in CategoryType.allCases {
            switch categoryType {
            case .analytics:
                reset(Analytics, in: group) { group.leave() }
            case .api:
                reset(API, in: group) { group.leave() }
            case .auth:
                reset(Auth, in: group) { group.leave() }
            case .dataStore:
                reset(DataStore, in: group) { group.leave() }
            case .geo:
                reset(Geo, in: group) { group.leave() }
            case .storage:
                reset(Storage, in: group) { group.leave() }
            case .predictions:
                reset(Predictions, in: group) { group.leave() }
            case .hub, .logging:
                // Hub and Logging should be reset after all other categories
                break
            }
        }

        group.wait()

        for categoryType in CategoryType.allCases {
            switch categoryType {
            case .hub:
                reset(Hub, in: group) { group.leave() }
            case .logging:
                reset(Logging, in: group) { group.leave() }
            default:
                break
            }
        }

#if canImport(UIKit)
        devMenu = nil
#endif

        group.wait()

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

    /// If `candidate` is `Resettable`, `enter()`s `group`, then invokes `candidate.reset(onComplete)` on a background
    /// queue. If `candidate` is not resettable, exits without invoking `onComplete`.
    private static func reset(_ candidate: Any, in group: DispatchGroup, onComplete: @escaping BasicClosure) {
        guard let resettable = candidate as? Resettable else {
            return
        }

        group.enter()
        resettable.reset(onComplete: onComplete)
    }

}
