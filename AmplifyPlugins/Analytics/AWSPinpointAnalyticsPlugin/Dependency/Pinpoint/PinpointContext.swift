//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSClientRuntime
import AWSPinpoint
import AWSPluginsCore
import Foundation

protocol UserDefaultsBehaviour {
    func save(_ value: UserDefaultsBehaviourValue?, forKey key: String)
    func removeObject(forKey key: String)
    func string(forKey key: String) -> String?
    func data(forKey key: String) -> Data?
}

protocol UserDefaultsBehaviourValue {}
extension String: UserDefaultsBehaviourValue {}
extension Data: UserDefaultsBehaviourValue {}

extension UserDefaults: UserDefaultsBehaviour {
    func save(_ value: UserDefaultsBehaviourValue?, forKey key: String) {
        set(value, forKey: key)
    }
}

struct PinpointContextConfiguration {
    typealias Megabyte = Int
    /// The Pinpoint AppId.
    let appId: String
    /// The session timeout in seconds. Defaults to 5 seconds.
    let sessionTimeout: TimeInterval
    /// The max storage size to use for event storage in MB. Defaults to 5 MB.
    let maxStorageSize: Megabyte

    init(appId: String,
         sessionTimeout: TimeInterval = 5,
         maxStorageSize: Megabyte = (1024 * 1024 * 5)) {
        self.appId = appId
        self.sessionTimeout = sessionTimeout
        self.maxStorageSize = maxStorageSize
    }
}

class PinpointContext {
    let configuration: PinpointContextConfiguration
    let pinpointClient: PinpointClientProtocol
    let userDefaults: UserDefaultsBehaviour
    
    lazy var uniqueId = retrieveUniqueId()
    
    lazy var analyticsClient: AnalyticsClient = {
        AnalyticsClient(context: self)
    }()
    
    lazy var targetingClient: EndpointClient = {
        EndpointClient(context: self)
    }()
    
    lazy var sessionTracker: SessionClient = {
        SessionClient(context: self)
    }()
    
    private let keychainStore: KeychainStoreBehavior

    init(with configuration: PinpointContextConfiguration,
         credentialsProvider: CredentialsProvider,
         region: String,
         userDefaults: UserDefaultsBehaviour = UserDefaults.standard,
         keychainStore: KeychainStoreBehavior = KeychainStore(service: Constants.Keychain.service)) throws {
        self.configuration = configuration
        self.keychainStore = keychainStore
        self.userDefaults = userDefaults
        let pinpointConfiguration = try PinpointClient.PinpointClientConfiguration(credentialsProvider: credentialsProvider,
                                                                                   frameworkMetadata: AmplifyAWSServiceConfiguration.frameworkMetaData(),
                                                                                   region: region)
        pinpointClient = PinpointClient(config: pinpointConfiguration)
    }
    
    private var legacyPreferencesFilePath: String? {
        let applicationSupportDirectoryUrls = FileManager.default.urls(for: .applicationSupportDirectory,
                                                                      in: .userDomainMask)
        let preferencesFileUrl = applicationSupportDirectoryUrls.first?
            .appendingPathComponent(Constants.Preferences.mobileAnalyticsRoot)
            .appendingPathComponent(configuration.appId)
            .appendingPathComponent(Constants.Preferences.fileName)
        
        return preferencesFileUrl?.path
    }
    
    private func removeLegacyPreferencesFile() {
        guard let preferencesPath = legacyPreferencesFilePath else {
            return
        }
        
        do {
            try FileManager.default.removeItem(atPath: preferencesPath)
        } catch {
            Amplify.Analytics.log.verbose("Cannot remove legacy preferences file")
        }
    }
    
    private func legacyUniqueId() -> String? {
        guard let preferencesPath = legacyPreferencesFilePath,
              FileManager.default.fileExists(atPath: preferencesPath),
              let preferencesJson = try? JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: preferencesPath)),
                                                                      options: .mutableContainers) as? [String: String] else {
            return nil
        }
        
        return preferencesJson[Constants.Preferences.uniqueIdKey]
    }
    
    private func retrieveUniqueId() -> String {
        // 1. Look for the UniqueId in the Keychain
        if let deviceUniqueId = try? keychainStore.getString(Constants.Keychain.uniqueIdKey) {
            return deviceUniqueId
        }
        
        // 2. Look for UniqueId in the legacy preferences file
        if let legacyUniqueId = legacyUniqueId() {
            do {
                // Attempt to migrate to Keychain
                try keychainStore.set(legacyUniqueId, key: Constants.Keychain.uniqueIdKey)
                Amplify.Analytics.log.verbose("Migrated Legacy Pinpoint UniqueId to Keychain: \(legacyUniqueId)")
                
                // Delete the old file
                removeLegacyPreferencesFile()
            } catch {
                Amplify.Analytics.log.error("Failed to migrate UniqueId to Keychain from preferences file")
                Amplify.Analytics.log.verbose("Fallback: Migrate UniqueId to UserDefaults: \(legacyUniqueId)")
                
                // Attempt to migrate to UserDefaults
                userDefaults.save(legacyUniqueId, forKey: Constants.Keychain.uniqueIdKey)
                
                // Delete the old file
                removeLegacyPreferencesFile()
            }

            return legacyUniqueId
        }

        // 3. Look for UniqueID in UserDefaults
        if let userDefaultsUniqueId = userDefaults.string(forKey: Constants.Keychain.uniqueIdKey) {
            // Attempt to migrate to Keychain
            do {
                try keychainStore.set(userDefaultsUniqueId, key: Constants.Keychain.uniqueIdKey)
                Amplify.Analytics.log.verbose("Migrated Pinpoint UniqueId from UserDefaults to Keychain: \(userDefaultsUniqueId)")
                
                // Delete the UserDefault entry
                userDefaults.removeObject(forKey: Constants.Keychain.uniqueIdKey)
            } catch {
                Amplify.Analytics.log.error("Failed to migrate UniqueId from UserDefaults to Keychain")
            }
            
            return userDefaultsUniqueId
        }
        
        // 4. Create a new ID
        let newUniqueId = UUID().uuidString
        do {
            try keychainStore.set(newUniqueId, key: Constants.Keychain.uniqueIdKey)
            Amplify.Analytics.log.verbose("Created new Pinpoint UniqueId and saved it to Keychain: \(newUniqueId)")
        } catch {
            Amplify.Analytics.log.error("Failed to save UniqueId in Keychain")
            Amplify.Analytics.log.verbose("Fallback: Created new Pinpoint UniqueId and saved it to UserDefaults: \(newUniqueId)")
            userDefaults.save(newUniqueId, forKey: Constants.Keychain.uniqueIdKey)
        }

        return newUniqueId
    }
}

extension PinpointContext {
    struct Constants {
        struct Preferences {
            static let mobileAnalyticsRoot = "com.amazonaws.MobileAnalytics"
            static let fileName = "preferences"
            static let uniqueIdKey = "UniqueId"
        }

        struct Keychain {
            static let service = "com.amazonaws.AWSPinpointContext"
            static let uniqueIdKey = "com.amazonaws.AWSPinpointContextKeychainUniqueIdKey"
        }
    }
}

class InternalPinpointClient {
    unowned let context: PinpointContext // ⚠️ This is known to be risky

    init(context: PinpointContext) {
        self.context = context
    }
}
