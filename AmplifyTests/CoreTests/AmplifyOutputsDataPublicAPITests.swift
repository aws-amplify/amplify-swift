//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

// Note: @testable is needed only for Amplify.reset() and Amplify.isConfigured in test helpers.
// The AmplifyOutputsData types themselves are verified accessible via plain `import Amplify`.
@testable import Amplify

/// Tests that verify `AmplifyOutputsData` and all nested types are accessible
/// without `@_spi(InternalAmplifyConfiguration)` — only standard `import Amplify` is needed.
class AmplifyOutputsDataPublicAPITests: XCTestCase {

    override func setUp() async throws {
        await Amplify.reset()
    }

    // MARK: - Programmatic Construction

    func testConstructAmplifyOutputsData() {
        let config = AmplifyOutputsData(
            auth: .init(
                awsRegion: "us-east-1",
                userPoolId: "us-east-1_abc",
                userPoolClientId: "client123"
            )
        )

        XCTAssertEqual(config.auth?.awsRegion, "us-east-1")
        XCTAssertEqual(config.auth?.userPoolId, "us-east-1_abc")
        XCTAssertEqual(config.auth?.userPoolClientId, "client123")
        XCTAssertNil(config.analytics)
        XCTAssertNil(config.storage)
        XCTAssertNil(config.data)
        XCTAssertNil(config.geo)
        XCTAssertNil(config.notifications)
    }

    func testConstructAuthWithAllFields() {
        let passwordPolicy = AmplifyOutputsData.Auth.PasswordPolicy(
            minLength: 8,
            requireNumbers: true,
            requireLowercase: true,
            requireUppercase: true,
            requireSymbols: false
        )

        let oauth = AmplifyOutputsData.Auth.OAuth(
            identityProviders: ["GOOGLE", "SIGN_IN_WITH_APPLE"],
            domain: "myapp.auth.us-east-1.amazoncognito.com",
            scopes: ["openid", "email", "profile"],
            redirectSignInUri: ["myapp://callback"],
            redirectSignOutUri: ["myapp://signout"],
            responseType: "code"
        )

        let auth = AmplifyOutputsData.Auth(
            awsRegion: "us-west-2",
            userPoolId: "us-west-2_xyz",
            userPoolClientId: "clientABC",
            identityPoolId: "us-west-2:identity-pool-id",
            passwordPolicy: passwordPolicy,
            oauth: oauth,
            standardRequiredAttributes: [.email, .phoneNumber],
            usernameAttributes: [.email],
            userVerificationTypes: [.email, .phoneNumber],
            unauthenticatedIdentitiesEnabled: true,
            mfaConfiguration: "OPTIONAL",
            mfaMethods: ["SMS", "TOTP"]
        )

        XCTAssertEqual(auth.awsRegion, "us-west-2")
        XCTAssertEqual(auth.identityPoolId, "us-west-2:identity-pool-id")
        XCTAssertEqual(auth.passwordPolicy?.minLength, 8)
        XCTAssertEqual(auth.passwordPolicy?.requireNumbers, true)
        XCTAssertEqual(auth.passwordPolicy?.requireSymbols, false)
        XCTAssertEqual(auth.oauth?.domain, "myapp.auth.us-east-1.amazoncognito.com")
        XCTAssertEqual(auth.oauth?.identityProviders, ["GOOGLE", "SIGN_IN_WITH_APPLE"])
        XCTAssertEqual(auth.oauth?.scopes, ["openid", "email", "profile"])
        XCTAssertEqual(auth.oauth?.redirectSignInUri, ["myapp://callback"])
        XCTAssertEqual(auth.oauth?.responseType, "code")
        XCTAssertEqual(auth.standardRequiredAttributes, [.email, .phoneNumber])
        XCTAssertEqual(auth.usernameAttributes, [.email])
        XCTAssertEqual(auth.userVerificationTypes, [.email, .phoneNumber])
        XCTAssertEqual(auth.unauthenticatedIdentitiesEnabled, true)
        XCTAssertEqual(auth.mfaConfiguration, "OPTIONAL")
        XCTAssertEqual(auth.mfaMethods, ["SMS", "TOTP"])
    }

    func testConstructAnalyticsConfig() {
        let analytics = AmplifyOutputsData.Analytics(
            amazonPinpoint: .init(awsRegion: "us-east-1", appId: "pinpoint-app-123")
        )

        XCTAssertEqual(analytics.amazonPinpoint?.awsRegion, "us-east-1")
        XCTAssertEqual(analytics.amazonPinpoint?.appId, "pinpoint-app-123")
    }

    func testConstructDataCategoryConfig() {
        let data = AmplifyOutputsData.DataCategory(
            awsRegion: "us-east-1",
            url: "https://abc123.appsync-api.us-east-1.amazonaws.com/graphql",
            apiKey: "da2-abcdefghijk",
            defaultAuthorizationType: .apiKey,
            authorizationTypes: [.apiKey, .amazonCognitoUserPools]
        )

        XCTAssertEqual(data.url, "https://abc123.appsync-api.us-east-1.amazonaws.com/graphql")
        XCTAssertEqual(data.apiKey, "da2-abcdefghijk")
        XCTAssertEqual(data.defaultAuthorizationType, .apiKey)
        XCTAssertEqual(data.authorizationTypes, [.apiKey, .amazonCognitoUserPools])
        XCTAssertNil(data.modelIntrospection)
    }

    func testConstructNotificationsConfig() {
        let notifications = AmplifyOutputsData.Notifications(
            awsRegion: "us-east-1",
            amazonPinpointAppId: "pinpoint-123",
            channels: [.apns, .fcm, .email]
        )

        XCTAssertEqual(notifications.amazonPinpointAppId, "pinpoint-123")
        XCTAssertEqual(notifications.channels, [.apns, .fcm, .email])
    }

    func testConstructGeoWithMapsAndIndices() {
        let geo = AmplifyOutputsData.Geo(
            awsRegion: "us-east-1",
            maps: .init(
                items: ["myMap": .init(style: "VectorEsriStreets")],
                default: "myMap"
            ),
            searchIndices: .init(items: ["myIndex"], default: "myIndex"),
            geofenceCollections: .init(items: ["myCollection"], default: "myCollection")
        )

        XCTAssertEqual(geo.maps?.items["myMap"]?.style, "VectorEsriStreets")
        XCTAssertEqual(geo.maps?.default, "myMap")
        XCTAssertEqual(geo.searchIndices?.items, ["myIndex"])
        XCTAssertEqual(geo.geofenceCollections?.default, "myCollection")
    }

    func testConstructStorageConfig() {
        let storage = AmplifyOutputsData.Storage(
            awsRegion: "us-east-1",
            bucketName: "my-bucket"
        )

        XCTAssertEqual(storage.awsRegion, "us-east-1")
        XCTAssertEqual(storage.bucketName, "my-bucket")
        XCTAssertNil(storage.buckets)
    }

    func testConstructStorageWithMultipleBuckets() {
        let storage = AmplifyOutputsData.Storage(
            awsRegion: "us-east-1",
            bucketName: "primary-bucket",
            buckets: [
                .init(name: "media", bucketName: "media-bucket", awsRegion: "us-east-1"),
                .init(name: "logs", bucketName: "logs-bucket", awsRegion: "us-west-2")
            ]
        )

        XCTAssertEqual(storage.buckets?.count, 2)
        XCTAssertEqual(storage.buckets?.first?.name, "media")
        XCTAssertEqual(storage.buckets?.last?.awsRegion, "us-west-2")
    }

    func testConstructGeoConfig() {
        let geo = AmplifyOutputsData.Geo(
            awsRegion: "us-east-1",
            maps: nil,
            searchIndices: nil,
            geofenceCollections: nil
        )

        XCTAssertEqual(geo.awsRegion, "us-east-1")
        XCTAssertNil(geo.maps)
    }

    func testConstructFullConfig() {
        let config = AmplifyOutputsData(
            analytics: nil,
            auth: .init(
                awsRegion: "us-east-1",
                userPoolId: "us-east-1_pool",
                userPoolClientId: "client"
            ),
            data: nil,
            geo: .init(awsRegion: "us-east-1"),
            notifications: nil,
            storage: .init(awsRegion: "us-east-1", bucketName: "bucket"),
            custom: nil
        )

        XCTAssertNotNil(config.auth)
        XCTAssertNotNil(config.geo)
        XCTAssertNotNil(config.storage)
        XCTAssertNil(config.analytics)
        XCTAssertNil(config.data)
        XCTAssertNil(config.notifications)
    }

    // MARK: - Configuration with AmplifyOutputsData

    func testConfigureAmplifyWithOutputsData() throws {
        let config = AmplifyOutputsData()
        try Amplify.configure(config)
        XCTAssertTrue(Amplify.isConfigured)
    }

    // MARK: - Type Accessibility

    func testNestedEnumsAccessible() {
        // Verify enums are usable without SPI import
        let usernameAttr: AmplifyOutputsData.Auth.UsernameAttributes = .email
        XCTAssertEqual(usernameAttr.rawValue, "email")

        let phoneAttr: AmplifyOutputsData.Auth.UsernameAttributes = .phoneNumber
        XCTAssertEqual(phoneAttr.rawValue, "phone_number")

        let verification: AmplifyOutputsData.Auth.UserVerificationType = .email
        XCTAssertEqual(verification.rawValue, "email")
    }

    func testAppSyncAuthTypesAccessible() {
        let authType: AmplifyOutputsData.AWSAppSyncAuthorizationType = .amazonCognitoUserPools
        XCTAssertEqual(authType.rawValue, "AMAZON_COGNITO_USER_POOLS")

        let iamType: AmplifyOutputsData.AWSAppSyncAuthorizationType = .awsIAM
        XCTAssertEqual(iamType.rawValue, "AWS_IAM")
    }

    func testPinpointChannelTypesAccessible() {
        let channel: AmplifyOutputsData.AmazonPinpointChannelType = .apns
        XCTAssertEqual(channel.rawValue, "APNS")
    }

    func testCognitoStandardAttributesAccessible() {
        let attr: AmplifyOutputsData.AmazonCognitoStandardAttributes = .email
        XCTAssertEqual(attr.rawValue, "email")

        let familyName: AmplifyOutputsData.AmazonCognitoStandardAttributes = .familyName
        XCTAssertEqual(familyName.rawValue, "family_name")
    }

    func testAWSRegionTypeAlias() {
        let region: AmplifyOutputsData.AWSRegion = "us-east-1"
        XCTAssertEqual(region, "us-east-1")
    }

    // MARK: - JSON Decoding

    func testDecodeFromJSON() throws {
        let json = """
        {
            "version": "1",
            "auth": {
                "aws_region": "us-east-1",
                "user_pool_id": "us-east-1_abc",
                "user_pool_client_id": "client123",
                "identity_pool_id": "us-east-1:id-pool",
                "username_attributes": ["email"],
                "user_verification_types": ["email", "phone_number"],
                "standard_required_attributes": ["email", "name"],
                "unauthenticated_identities_enabled": true
            },
            "storage": {
                "aws_region": "us-east-1",
                "bucket_name": "my-bucket"
            }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let config = try decoder.decode(AmplifyOutputsData.self, from: json)

        XCTAssertEqual(config.auth?.userPoolId, "us-east-1_abc")
        XCTAssertEqual(config.auth?.identityPoolId, "us-east-1:id-pool")
        XCTAssertEqual(config.auth?.usernameAttributes, [.email])
        XCTAssertEqual(config.auth?.userVerificationTypes, [.email, .phoneNumber])
        XCTAssertEqual(config.auth?.unauthenticatedIdentitiesEnabled, true)
        XCTAssertEqual(config.storage?.bucketName, "my-bucket")
    }

    // MARK: - AmplifyOutputs resolver

    func testResolveConfigurationAccessible() throws {
        let outputs = AmplifyOutputs.data("""
        {
            "version": "1",
            "storage": {
                "aws_region": "us-west-2",
                "bucket_name": "test-bucket"
            }
        }
        """.data(using: .utf8)!)

        let resolved = try outputs.resolveConfiguration()
        XCTAssertEqual(resolved.storage?.awsRegion, "us-west-2")
        XCTAssertEqual(resolved.storage?.bucketName, "test-bucket")
    }
}
