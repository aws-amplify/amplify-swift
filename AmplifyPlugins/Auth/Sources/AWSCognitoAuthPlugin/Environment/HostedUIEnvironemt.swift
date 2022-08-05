//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol HostedUIEnvironment: Environment {

    typealias HostedUISessionFactory = () -> HostedUISessionBehavior

    typealias URLSessionFactory = () -> URLSession

    typealias RandomStringFactory = () -> RandomStringBehavior

    var configuration: HostedUIConfigurationData { get }

    var hostedUISessionFactory: HostedUISessionFactory { get }

    var urlSessionFactory: URLSessionFactory { get }

    var randomStringFactory: RandomStringFactory { get }
}

struct BasicHostedUIEnvironment: HostedUIEnvironment {

    let configuration: HostedUIConfigurationData

    let hostedUISessionFactory: HostedUISessionFactory

    let urlSessionFactory: URLSessionFactory

    let randomStringFactory: RandomStringFactory
}
