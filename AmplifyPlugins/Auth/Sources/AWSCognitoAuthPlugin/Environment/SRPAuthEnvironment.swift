//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//



// TODO: Refactor this: shouldn't be depending on HLC constructs like
// AWSCognitoIdentityUserPoolConfiguration nor AWSServiceInfo, nor even really on
// SRP dependencies
struct BasicSRPAuthEnvironment: SRPAuthEnvironment {

    typealias SRPClientFactory = (String, String) throws -> SRPClientBehavior
    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior

    // Required
    let userPoolConfiguration: UserPoolConfigurationData
    let cognitoUserPoolFactory: CognitoUserPoolFactory

    // Optional
    let eventIDFactory: EventIDFactory
    let srpClientFactory: SRPClientFactory
    let srpConfiguration: SRPCommonConfig

    init(
        userPoolConfiguration: UserPoolConfigurationData,
        cognitoUserPoolFactory: @escaping CognitoUserPoolFactory,
        eventIDFactory: @escaping EventIDFactory = UUIDFactory.factory,
        srpClientFactory: @escaping SRPClientFactory = AmplifySRPClient.init(NHexValue:gHexValue:),
        srpConfiguration: SRPCommonConfig = SRPCommonConfig()
    ) {
        self.userPoolConfiguration = userPoolConfiguration
        self.cognitoUserPoolFactory = cognitoUserPoolFactory

        self.eventIDFactory = eventIDFactory
        self.srpClientFactory = srpClientFactory
        self.srpConfiguration = srpConfiguration
    }
}

// TODO: Convert to enum
struct SRPCommonConfig {
    // Use the 3072 bit from - https://datatracker.ietf.org/doc/html/rfc5054#appendix-A
    let nHexValue =
    "FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD129024E088A67CC74020BBEA63B139B2" +
    "2514A08798E3404DDEF9519B3CD3A431B302B0A6DF25F14374FE1356D6D51C245E485B576625E7E" +
    "C6F44C42E9A637ED6B0BFF5CB6F406B7EDEE386BFB5A899FA5AE9F24117C4B1FE649286651ECE45" +
    "B3DC2007CB8A163BF0598DA48361C55D39A69163FA8FD24CF5F83655D23DCA3AD961C62F3562085" +
    "52BB9ED529077096966D670C354E4ABC9804F1746C08CA18217C32905E462E36CE3BE39E772C180" +
    "E86039B2783A2EC07A28FB5C55DF06F4C52C9DE2BCBF6955817183995497CEA956AE515D2261898" +
    "FA051015728E5A8AAAC42DAD33170D04507A33A85521ABDF1CBA64ECFB850458DBEF0A8AEA71575" +
    "D060C7DB3970F85A6E1E4C7ABF5AE8CDB0933D71E8C94E04A25619DCEE3D2261AD2EE6BF12FFA06" +
    "D98A0864D87602733EC86A64521F2B18177B200CBBE117577A615D6C770988C0BAD946E208E24FA" +
    "074E5AB3143DB5BFCE0FD108E4B82D120A93AD2CAFFFFFFFFFFFFFFFF"
    let gHexValue = "2"
}

protocol SRPAuthEnvironment: Environment {
    typealias SRPClientFactory = (String, String) throws -> SRPClientBehavior
    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior

    var userPoolConfiguration: UserPoolConfigurationData { get }
    var cognitoUserPoolFactory: CognitoUserPoolFactory { get }
    var eventIDFactory: EventIDFactory { get }
    var srpClientFactory: SRPClientFactory { get }
    var srpConfiguration: SRPCommonConfig { get }
}

extension AuthEnvironment: SRPAuthEnvironment {

    var eventIDFactory: EventIDFactory {
        srpSignInEnvironment.srpAuthEnvironment.eventIDFactory
    }

    var srpClientFactory: SRPClientFactory {
        srpSignInEnvironment.srpAuthEnvironment.srpClientFactory
    }

    var srpConfiguration: SRPCommonConfig {
        srpSignInEnvironment.srpAuthEnvironment.srpConfiguration
    }
}
