//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package protocol HostedUIEnvironment: Environment {

    typealias HostedUISessionFactory = @Sendable () -> HostedUISessionBehavior

    typealias URLSessionFactory = @Sendable () -> URLSession

    typealias RandomStringFactory = @Sendable () -> RandomStringBehavior

    /// Told the refresh token of every token response the sign-in's code exchange gets, before anything checks it.
    typealias IssuedRefreshTokenObserver = @Sendable (String) -> Void

    var configuration: HostedUIConfigurationData { get }

    var hostedUISessionFactory: HostedUISessionFactory { get }

    var urlSessionFactory: URLSessionFactory { get }

    var randomStringFactory: RandomStringFactory { get }

    /// What a hosted-UI sign-in in this environment checks about the tokens it gets back.
    /// `AmplifyCognitoClient` builds an environment per operation, so this is
    /// per flow there. The plugin never sets it, so it is `.none`, which verifies nothing.
    var identityPolicy: HostedUIIdentityPolicy { get }

    /// Sees each refresh token the code exchange is issued, so a caller that has stopped the flow can revoke one
    /// that arrives after it stopped: the machine drops the response then, and the token would be orphaned.
    /// `AmplifyCognitoClient` hands it to the operation's issued-token tap. The plugin leaves it `nil`.
    var issuedRefreshTokenObserver: IssuedRefreshTokenObserver? { get }
}

package struct BasicHostedUIEnvironment: HostedUIEnvironment {

    package let configuration: HostedUIConfigurationData

    package let hostedUISessionFactory: HostedUISessionFactory

    package let urlSessionFactory: URLSessionFactory

    package let randomStringFactory: RandomStringFactory

    package let identityPolicy: HostedUIIdentityPolicy

    package let issuedRefreshTokenObserver: IssuedRefreshTokenObserver?

    package init(
        configuration: HostedUIConfigurationData,
        hostedUISessionFactory: @escaping HostedUISessionFactory,
        urlSessionFactory: @escaping URLSessionFactory,
        randomStringFactory: @escaping RandomStringFactory,
        identityPolicy: HostedUIIdentityPolicy = .none,
        issuedRefreshTokenObserver: IssuedRefreshTokenObserver? = nil
    ) {
        self.issuedRefreshTokenObserver = issuedRefreshTokenObserver
        self.configuration = configuration
        self.hostedUISessionFactory = hostedUISessionFactory
        self.urlSessionFactory = urlSessionFactory
        self.randomStringFactory = randomStringFactory
        self.identityPolicy = identityPolicy
    }
}
