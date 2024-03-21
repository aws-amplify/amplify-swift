//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Network

struct ConnectivityPath {
    let status: ConnectivityStatus
    let availableInterfaces: [ConnectivityInterface]
    let isExpensive: Bool
    let supportsDNS: Bool
    let supportsIPv4: Bool
    let supportsIPv6: Bool

    init(
        status: ConnectivityStatus = .unsatisfied,
        availableInterfaces: [ConnectivityInterface] = [],
        isExpensive: Bool = false,
        supportsDNS: Bool = false,
        supportsIPv4: Bool = false,
        supportsIPv6: Bool = false
    ) {
        self.status = status
        self.availableInterfaces = availableInterfaces
        self.isExpensive = isExpensive
        self.supportsDNS = supportsDNS
        self.supportsIPv4 = supportsIPv4
        self.supportsIPv6 = supportsIPv6
    }
}

extension ConnectivityPath: CustomStringConvertible {
    var description: String {
        [
            "\(status): \(availableInterfaces.description)",
            "Expensive = \(isExpensive ? "YES" : "NO")",
            "DNS = \(supportsDNS ? "YES" : "NO")",
            "IPv4 = \(supportsIPv4 ? "YES" : "NO")",
            "IPv6 = \(supportsIPv6 ? "YES" : "NO")"
        ].joined(separator: "; ")
    }
}

extension ConnectivityPath {
    @available(iOS 12.0, *)
    init(path: NWPath) {
        self.status = ConnectivityStatus(status: path.status)
        self.availableInterfaces = path.availableInterfaces.map { ConnectivityInterface(interface: $0) }
        self.isExpensive = path.isExpensive
        self.supportsDNS = path.supportsDNS
        self.supportsIPv4 = path.supportsIPv4
        self.supportsIPv6 = path.supportsIPv6
    }
}

enum ConnectivityInterfaceType: String {
    case other
    case wifi
    case cellular
    case wiredEthernet
    case loopback
}

extension ConnectivityInterfaceType {
    @available(iOS 12.0, *)
    init(interfaceType: NWInterface.InterfaceType) {
        switch interfaceType {
        case .other:
            self = .other
        case .wifi:
            self = .wifi
        case .cellular:
            self = .cellular
        case .wiredEthernet:
            self = .wiredEthernet
        case .loopback:
            self = .loopback
        @unknown default:
            self = .other
        }
    }
}

struct ConnectivityInterface {
    public let name: String
    public let type: ConnectivityInterfaceType

    public init(name: String, type: ConnectivityInterfaceType) {
        self.name = name
        self.type = type
    }
}
extension ConnectivityInterface {
    @available(iOS 12.0, *)
    init(interface: NWInterface) {
        self.name = interface.name
        self.type = ConnectivityInterfaceType(interfaceType: interface.type)
    }
}

enum ConnectivityStatus: String {
    case satisfied
    case unsatisfied
    case requiresConnection
}

extension ConnectivityStatus {
    @available(iOS 12.0, *)
    init(status: NWPath.Status) {
        switch status {
        case .satisfied:
            self = .satisfied
        case .unsatisfied:
            self = .unsatisfied
        case .requiresConnection:
            self = .requiresConnection
        @unknown default:
            self = .unsatisfied
        }
    }
}
