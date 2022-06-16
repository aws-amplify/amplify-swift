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

// MARK: - UserDefaultsBehaviour
protocol UserDefaultsBehaviour {
    func save(_ value: UserDefaultsBehaviourValue?, forKey key: String)
    func removeObject(forKey key: String)
    func string(forKey key: String) -> String?
    func data(forKey key: String) -> Data?
    func object(forKey: String) -> Any?
}

protocol UserDefaultsBehaviourValue {}
extension String: UserDefaultsBehaviourValue {}
extension Data: UserDefaultsBehaviourValue {}
extension Dictionary: UserDefaultsBehaviourValue {}

extension UserDefaults: UserDefaultsBehaviour {
    func save(_ value: UserDefaultsBehaviourValue?, forKey key: String) {
        set(value, forKey: key)
    }
}

// MARK: - FileManagerBehaviour
protocol FileManagerBehaviour {
    func removeItem(atPath path: String) throws
    func urls(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL]
    func fileExists(atPath path: String) -> Bool
    func fileSize(for url: URL) -> Byte
    func createDirectory(atPath path: String, withIntermediateDirectories createIntermediates: Bool) throws
}

extension FileManager: FileManagerBehaviour, DefaultLogger {
    func createDirectory(atPath path: String, withIntermediateDirectories createIntermediates: Bool) throws {
        try createDirectory(atPath: path,
                        withIntermediateDirectories: createIntermediates,
                        attributes: nil)
    }

    func fileSize(for url: URL) -> Byte {
        do {
            let attributes = try self.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Byte ?? 0
        } catch {
            log.error("Error getting file size with error \(error)")
        }
        return 0
    }

}

typealias Byte = Int

// MARK: - PinpointContext
/// The configuration object containing the necessary and optional configurations required to use AWSPinpoint
struct PinpointContextConfiguration {
    /// The Pinpoint AppId.
    let appId: String
    /// The Pinpoint region
    let region: String
    /// Used to retrieve the proper AWSCredentials when creating the PinpointCLient
    let credentialsProvider: CredentialsProvider
    /// The session timeout in seconds. Defaults to 5 seconds.
    let sessionTimeout: TimeInterval
    /// The max storage size to use for event storage in bytes. Defaults to 5 MB.
    let maxStorageSize: Byte

    /// Indicates if the App is in Debug or Release build. Defaults to `false`
    /// Setting this flag to true will set the Endpoint Profile to have a channel type of "APNS_SANDBOX".
    let isDebug: Bool

    /// Indicates whether or not the Targeting Client should set application level OptOut.
    /// Use it to configure whether or not the client should receive push notifications at an application level.
    /// If System-level notifications for this application are disabled, this will be ignored.
    let isApplicationLevelOptOut: Bool

    /// Indicates whether to track application sessions. Defaults to `true`
    let shouldTrackAppSessions: Bool

    init(appId: String,
         region: String,
         credentialsProvider: CredentialsProvider,
         sessionTimeout: TimeInterval = 5,
         maxStorageSize: Byte = (1024 * 1024 * 5),
         isDebug: Bool = false,
         isApplicationLevelOptOut: Bool = false,
         shouldTrackAppSessions: Bool = true) {
        self.appId = appId
        self.region = region
        self.credentialsProvider = credentialsProvider
        self.sessionTimeout = sessionTimeout
        self.maxStorageSize = maxStorageSize
        self.isDebug = isDebug
        self.isApplicationLevelOptOut = isApplicationLevelOptOut
        self.shouldTrackAppSessions = shouldTrackAppSessions
    }
}

/// An internal helper struct used to group all the storage dependencies that can be provided.
private struct PinpointContextStorage {
    let userDefaults: UserDefaultsBehaviour
    let keychainStore: KeychainStoreBehavior
    let fileManager: FileManagerBehaviour
    let archiver: AmplifyArchiverBehaviour
}

class PinpointContext {
    let pinpointClient: PinpointClientProtocol
    let endpointClient: EndpointClientBehaviour
    let sessionClient: SessionClientBehaviour
    let analyticsClient: AnalyticsClientBehaviour

    private let uniqueId: String
    private let configuration: PinpointContextConfiguration
    private let storage: PinpointContextStorage

    init(with configuration: PinpointContextConfiguration,
         currentDevice: Device = DeviceProvider.current,
         userDefaults: UserDefaultsBehaviour = UserDefaults.standard,
         keychainStore: KeychainStoreBehavior = KeychainStore(service: PinpointContext.Constants.Keychain.service),
         fileManager: FileManagerBehaviour = FileManager.default,
         archiver: AmplifyArchiverBehaviour = AmplifyArchiver()) throws {
        storage = PinpointContextStorage(userDefaults: userDefaults,
                                         keychainStore: keychainStore,
                                         fileManager: fileManager,
                                         archiver: archiver)
        uniqueId = Self.retrieveUniqueId(applicationId: configuration.appId, storage: storage)

        let pinpointConfiguration = try PinpointClient.PinpointClientConfiguration(
            region: configuration.region,
            credentialsProvider: configuration.credentialsProvider,
            frameworkMetadata: AmplifyAWSServiceConfiguration.frameworkMetaData()
        )
        pinpointClient = PinpointClient(config: pinpointConfiguration)

        endpointClient = EndpointClient(configuration: .init(appId: configuration.appId,
                                                             uniqueDeviceId: uniqueId,
                                                             isDebug: configuration.isDebug,
                                                             isOptOut: configuration.isApplicationLevelOptOut),
                                        pinpointClient: pinpointClient,
                                        currentDevice: currentDevice,
                                        userDefaults: userDefaults)

        sessionClient = SessionClient(archiver: archiver,
                                      configuration: .init(appId: configuration.appId,
                                                           uniqueDeviceId: uniqueId,
                                                           sessionTimeout: configuration.sessionTimeout),
                                      endpointClient: endpointClient,
                                      userDefaults: userDefaults)

        let sessionProvider: () -> PinpointSession = { [weak sessionClient] in
            guard let sessionClient = sessionClient else {
                fatalError("SessionClient was deallocated")
            }
            return sessionClient.currentSession
        }

        analyticsClient = try AnalyticsClient(applicationId: configuration.appId,
                                              pinpointClient: pinpointClient,
                                              sessionProvider: sessionProvider)
        sessionClient.analyticsClient = analyticsClient
        if configuration.shouldTrackAppSessions {
            sessionClient.startPinpointSession()
        }
        self.configuration = configuration
    }

    private static func legacyPreferencesFilePath(applicationId: String,
                                                  storage: PinpointContextStorage) -> String? {
        let applicationSupportDirectoryUrls = storage.fileManager.urls(for: .applicationSupportDirectory,
                                                                            in: .userDomainMask)
        let preferencesFileUrl = applicationSupportDirectoryUrls.first?
            .appendingPathComponent(Constants.Preferences.mobileAnalyticsRoot)
            .appendingPathComponent(applicationId)
            .appendingPathComponent(Constants.Preferences.fileName)

        return preferencesFileUrl?.path
    }

    private static func removeLegacyPreferencesFile(applicationId: String,
                                                    storage: PinpointContextStorage) {
        guard let preferencesPath = legacyPreferencesFilePath(applicationId: applicationId,
                                                              storage: storage) else {
            return
        }

        do {
            try storage.fileManager.removeItem(atPath: preferencesPath)
        } catch {
            log.verbose("Cannot remove legacy preferences file")
        }
    }

    private static func legacyUniqueId(applicationId: String,
                                       storage: PinpointContextStorage) -> String? {
        guard let preferencesPath = legacyPreferencesFilePath(applicationId: applicationId,
                                                              storage: storage),
              storage.fileManager.fileExists(atPath: preferencesPath),
              let preferencesJson = try? JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: preferencesPath)),
                                                                      options: .mutableContainers) as? [String: String] else {
            return nil
        }

        return preferencesJson[Constants.Preferences.uniqueIdKey]
    }

    /**
     Attempts to retrieve a previously generated Device Unique ID.
     
     This value can be present in 3 places:
     1. In a preferences file stored in disk
     2. In UserDefauls
     3. In the Keychain
     
     1 and 2 are legacy storage options that are supportted for backwards compability, but once retrieved those values will be migrated to the Keychain.
     
     If no existing Device Unique ID is found, a new one will be generated and stored in the Keychain.
     
     - Returns: A string representing the Device Unique ID
     */
    private static func retrieveUniqueId(applicationId: String,
                                         storage: PinpointContextStorage) -> String {
        // 1. Look for the UniqueId in the Keychain
        if let deviceUniqueId = try? storage.keychainStore.getString(Constants.Keychain.uniqueIdKey) {
            return deviceUniqueId
        }

        // 2. Look for UniqueId in the legacy preferences file
        if let legacyUniqueId = legacyUniqueId(applicationId: applicationId, storage: storage) {
            do {
                // Attempt to migrate to Keychain
                try storage.keychainStore.set(legacyUniqueId, key: Constants.Keychain.uniqueIdKey)
                log.verbose("Migrated Legacy Pinpoint UniqueId to Keychain: \(legacyUniqueId)")

                // Delete the old file
                removeLegacyPreferencesFile(applicationId: applicationId, storage: storage)
            } catch {
                log.error("Failed to migrate UniqueId to Keychain from preferences file")
                log.verbose("Fallback: Migrate UniqueId to UserDefaults: \(legacyUniqueId)")

                // Attempt to migrate to UserDefaults
                storage.userDefaults.save(legacyUniqueId, forKey: Constants.Keychain.uniqueIdKey)

                // Delete the old file
                removeLegacyPreferencesFile(applicationId: applicationId, storage: storage)
            }

            return legacyUniqueId
        }

        // 3. Look for UniqueID in UserDefaults
        if let userDefaultsUniqueId = storage.userDefaults.string(forKey: Constants.Keychain.uniqueIdKey) {
            // Attempt to migrate to Keychain
            do {
                try storage.keychainStore.set(userDefaultsUniqueId, key: Constants.Keychain.uniqueIdKey)
                log.verbose("Migrated Pinpoint UniqueId from UserDefaults to Keychain: \(userDefaultsUniqueId)")

                // Delete the UserDefault entry
                storage.userDefaults.removeObject(forKey: Constants.Keychain.uniqueIdKey)
            } catch {
                log.error("Failed to migrate UniqueId from UserDefaults to Keychain")
            }

            return userDefaultsUniqueId
        }

        // 4. Create a new ID
        let newUniqueId = UUID().uuidString
        do {
            try storage.keychainStore.set(newUniqueId, key: Constants.Keychain.uniqueIdKey)
            log.verbose("Created new Pinpoint UniqueId and saved it to Keychain: \(newUniqueId)")
        } catch {
            log.error("Failed to save UniqueId in Keychain")
            log.verbose("Fallback: Created new Pinpoint UniqueId and saved it to UserDefaults: \(newUniqueId)")
            storage.userDefaults.save(newUniqueId, forKey: Constants.Keychain.uniqueIdKey)
        }

        return newUniqueId
    }
}

// MARK: - DefaultLogger
extension PinpointContext: DefaultLogger {}

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

protocol InternalPinpointClient {
    var context: PinpointContext { get }
}
