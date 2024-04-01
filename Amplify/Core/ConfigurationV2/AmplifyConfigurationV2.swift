//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Represents Amplify's Gen2 configuration for all categories intended to be used in an application.
///
/// See: [Amplify.configure](x-source-tag://Amplify.configure)
///
/// - Tag: AmplifyConfigurationV2
///
@_spi(InternalAmplifyConfiguration)
public struct AmplifyConfigurationV2: Codable {
    public let version: String
    public let analytics: Analytics?
    public let auth: Auth?
    public let data: DataCategory?
    public let geo: Geo?
    public let notifications: Notifications?
    public let storage: Storage?
    public let custom: CustomOutput?

    @_spi(InternalAmplifyConfiguration)
    public struct Analytics: Codable {
        public let amazonPinpoint: AmazonPinpoint?

        public struct AmazonPinpoint: Codable {
            public let awsRegion: AWSRegion
            public let appId: String
        }
    }

    @_spi(InternalAmplifyConfiguration)
    public struct Auth: Codable {
        public let awsRegion: AWSRegion
        public let authenticationFlowType: String
        public let userPoolId: String
        public let userPoolClientId: String
        public let identityPoolId: String
        public let passwordPolicy: PasswordPolicy?
        public let oauth: OAuth?
        public let standardAttributes: [AmazonCognitoStandardAttributes]
        public let usernameAttributes: [String]
        public let userVerificationMechanisms: [String]
        public let unauthenticatedIdentitiesEnabled: Bool?
        public let mfaConfiguration: String?
        public let mfaMethods: [String]

        public struct PasswordPolicy: Codable {
            public let minLength: UInt
            public let requireNumbers: Bool
            public let requireLowercase: Bool
            public let requireUppercase: Bool
            public let requireSymbols: Bool
        }

        public struct OAuth: Codable {
            public let identityProviders: [String]
            public let domain: String
            public let scopes: [String]
            public let redirectSignInUri: [String]
            public let redirectSignOutUri: [String]
            public let responseType: String
        }
    }

    public struct DataCategory: Codable {
        public let awsRegion: AWSRegion
        public let url: String
        public let modelIntrospection: JSONValue
        public let apiKey: String?
        public let defaultAuthorizationType: AWSAppSyncAuthorizationType
        public let authorizationTypes: [AWSAppSyncAuthorizationType]
    }

    @_spi(InternalAmplifyConfiguration)
    public struct Geo: Codable {
        public let awsRegion: AWSRegion
        public let maps: Maps
        public let searchIndices: SearchIndices
        public let geofenceCollections: GeofenceCollections

        public struct Maps: Codable {
            public let items: [String: AmazonLocationServiceConfig]
            public let `default`: String

            public struct AmazonLocationServiceConfig: Codable {
                public let name: String
                public let style: String
            }
        }

        public struct SearchIndices: Codable {
            public let items: [String]
            public let `default`: String
        }

        public struct GeofenceCollections: Codable {
            public let items: [String]
            public let `default`: String
        }
    }

    @_spi(InternalAmplifyConfiguration)
    public struct Notifications: Codable {
        public let awsRegion: String
        public let amazonPinpointAppId: String
        public let channels: [AmazonPinpointChannelType]
    }

    @_spi(InternalAmplifyConfiguration)
    public struct Storage: Codable {
        public let awsRegion: AWSRegion
        public let bucketName: String
    }

    @_spi(InternalAmplifyConfiguration)
    public struct CustomOutput: Codable {}

    @_spi(InternalAmplifyConfiguration)
    public typealias AWSRegion = String

    @_spi(InternalAmplifyConfiguration)
    public enum AmazonCognitoStandardAttributes: String, Codable, CodingKeyRepresentable {
        case address
        case birthdate
        case email
        case familyName
        case gender
        case givenName
        case locale
        case middleName
        case name
        case nickname
        case phoneNumber
        case picture
        case preferredUsername
        case profile
        case sub
        case updatedAt
        case website
        case zoneinfo
    }

    @_spi(InternalAmplifyConfiguration)
    public enum AWSAppSyncAuthorizationType: String, Codable {
        case amazonCognitoUserPools = "AMAZON_COGNITO_USER_POOLS"
        case apiKey = "API_KEY"
        case awsIAM = "AWS_IAM"
        case awsLambda = "AWS_LAMBDA"
        case openIDConnect = "OPENID_CONNECT"
    }

    @_spi(InternalAmplifyConfiguration)
    public enum AmazonPinpointChannelType: String, Codable {
        case inAppMessaging = "IN_APP_MESSAGING"
        case fcm = "FCM"
        case apns = "APNS"
        case email = "EMAIL"
        case sms = "SMS"
    }
}

// MARK: - Configure
public enum ConfigurationFormat {
    case amplifyOutputs
}

extension Amplify {

    /// Explicit API to configure with `amplify-outputs.json`.
    /// 
    /// - Parameter with: format of the configuration file
    ///     Only one explicit format is supported,`.amplifyOutputs`.
    public static func configure(with: ConfigurationFormat) throws {
        let resolvedConfiguration: AmplifyConfigurationV2
        do {
            resolvedConfiguration = try AmplifyConfigurationV2(bundle: Bundle.main)
        } catch {
            log.info("Failed to find Amplify configuration.")
            if isRunningForSwiftUIPreviews {
                log.info("Running for SwiftUI previews with no configuration file present, skipping configuration.")
                return
            } else {
                throw error
            }
        }

        try configure(resolvedConfiguration)
    }

    /// Configures Amplify with the specified configuration.
    ///
    /// This method must be invoked after registering plugins, and before using any Amplify category. It must not be
    /// invoked more than once.
    ///
    /// **Lifecycle**
    ///
    /// Internally, Amplify configures the Hub and Logging categories first, so they are available to plugins in the
    /// remaining categories during the configuration phase. Plugins for the Hub and Logging categories must not
    /// assume that any other categories are available.
    ///
    /// After Amplify has configured all of its categories, it will dispatch a `HubPayload.EventName.Amplify.configured`
    /// event to each Amplify Hub channel. After this point, plugins may invoke calls on other Amplify categories.
    ///
    /// - Parameter configuration: The AmplifyConfigurationV2 for specified Categories
    ///
    /// - Tag: Amplify.configure
    static func configure(_ configuration: AmplifyConfigurationV2) throws {
        // Always configure logging first since Auth dependings on logging
        try configure(CategoryType.logging.category, using: configuration)

        // Always configure Hub and Auth next, so they are available to other categories.
        // Auth is a special case for other plugins which depend on using Auth when being configured themselves.
        let manuallyConfiguredCategories = [CategoryType.hub, .auth]
        for categoryType in manuallyConfiguredCategories {
            try configure(categoryType.category, using: configuration)
        }

        // Looping through all categories to ensure we don't accidentally forget a category at some point in the future
        let remainingCategories = CategoryType.allCases.filter { !manuallyConfiguredCategories.contains($0) }
        for categoryType in remainingCategories {
            switch categoryType {
            case .analytics:
                try configure(Analytics, using: configuration)
            case .api:
                try configure(API, using: configuration)
            case .dataStore:
                try configure(DataStore, using: configuration)
            case .geo:
                try configure(Geo, using: configuration)
            case .predictions:
                try configure(Predictions, using: configuration)
            case .pushNotifications:
                try configure(Notifications.Push, using: configuration)
            case .storage:
                try configure(Storage, using: configuration)
            case .hub, .logging, .auth:
                // Already configured
                break
            }
        }
        isConfigured = true

        notifyAllHubChannels()
    }


    /// If `candidate` is `CategoryConfigurable`, then invokes `candidate.configure(using: configuration)`.
    private static func configure(_ candidate: Category, using configuration: AmplifyConfigurationV2) throws {
        guard let configurable = candidate as? CategoryConfigurable else {
            return
        }

        try configurable.configure(using: configuration)
    }
}
