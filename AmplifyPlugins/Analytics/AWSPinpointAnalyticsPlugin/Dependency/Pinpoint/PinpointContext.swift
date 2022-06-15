//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSClientRuntime
import AWSPinpoint
import AWSPluginsCore
import Amplify
import Foundation

// MARK: - UserDefaultsBehaviour
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

// MARK: - FileManagerBehaviour
protocol FileManagerBehaviour {
  func removeItem(atPath path: String) throws
  func urls(
    for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask
  ) -> [URL]
  func fileExists(atPath path: String) -> Bool
  func fileSize(for url: URL) -> Byte
}

extension FileManager: FileManagerBehaviour, DefaultLogger {
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
struct PinpointContextConfiguration {
  /// The Pinpoint AppId.
  let appId: String
  /// The session timeout in seconds. Defaults to 5 seconds.
  let sessionTimeout: TimeInterval
  /// The max storage size to use for event storage in MB. Defaults to 5 MB.
  let maxStorageSize: Byte

  init(
    appId: String,
    sessionTimeout: TimeInterval = 5,
    maxStorageSize: Byte = (1024 * 1024 * 5)
  ) {
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

  lazy var analyticsClient: AnalyticsClientBehaviour = {
    AnalyticsClient(context: self)
  }()

  lazy var targetingClient: EndpointClient = {
    EndpointClient(context: self)
  }()

  lazy var sessionClient: SessionClientBehaviour = {
    SessionClient(context: self)
  }()

  private let keychainStore: KeychainStoreBehavior
  private let fileManager: FileManagerBehaviour

  init(
    with configuration: PinpointContextConfiguration,
    credentialsProvider: CredentialsProvider,
    region: String,
    userDefaults: UserDefaultsBehaviour = UserDefaults.standard,
    keychainStore: KeychainStoreBehavior = KeychainStore(service: Constants.Keychain.service),
    fileManager: FileManagerBehaviour = FileManager.default
  ) throws {
    self.configuration = configuration
    self.keychainStore = keychainStore
    self.userDefaults = userDefaults
    self.fileManager = fileManager
    let pinpointConfiguration = try PinpointClient.PinpointClientConfiguration(
      region: region,
      credentialsProvider: credentialsProvider,
      frameworkMetadata: AmplifyAWSServiceConfiguration.frameworkMetaData())
    pinpointClient = PinpointClient(config: pinpointConfiguration)
  }

  private var legacyPreferencesFilePath: String? {
    let applicationSupportDirectoryUrls = fileManager.urls(
      for: .applicationSupportDirectory,
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
      try fileManager.removeItem(atPath: preferencesPath)
    } catch {
      log.verbose("Cannot remove legacy preferences file")
    }
  }

  private func legacyUniqueId() -> String? {
    guard let preferencesPath = legacyPreferencesFilePath,
      fileManager.fileExists(atPath: preferencesPath),
      let preferencesJson = try? JSONSerialization.jsonObject(
        with: Data(contentsOf: URL(fileURLWithPath: preferencesPath)),
        options: .mutableContainers) as? [String: String]
    else {
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
        log.verbose("Migrated Legacy Pinpoint UniqueId to Keychain: \(legacyUniqueId)")

        // Delete the old file
        removeLegacyPreferencesFile()
      } catch {
        log.error("Failed to migrate UniqueId to Keychain from preferences file")
        log.verbose("Fallback: Migrate UniqueId to UserDefaults: \(legacyUniqueId)")

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
        log.verbose(
          "Migrated Pinpoint UniqueId from UserDefaults to Keychain: \(userDefaultsUniqueId)")

        // Delete the UserDefault entry
        userDefaults.removeObject(forKey: Constants.Keychain.uniqueIdKey)
      } catch {
        log.error("Failed to migrate UniqueId from UserDefaults to Keychain")
      }

      return userDefaultsUniqueId
    }

    // 4. Create a new ID
    let newUniqueId = UUID().uuidString
    do {
      try keychainStore.set(newUniqueId, key: Constants.Keychain.uniqueIdKey)
      log.verbose("Created new Pinpoint UniqueId and saved it to Keychain: \(newUniqueId)")
    } catch {
      log.error("Failed to save UniqueId in Keychain")
      log.verbose(
        "Fallback: Created new Pinpoint UniqueId and saved it to UserDefaults: \(newUniqueId)")
      userDefaults.save(newUniqueId, forKey: Constants.Keychain.uniqueIdKey)
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
