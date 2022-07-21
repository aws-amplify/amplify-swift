//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import Amplify

extension TypeRegistry: InstanceFactory {}

typealias TypeFactory = (String?) -> Any

/// Supports testing by allowing instances for a type to be created for use in mocks.
class TypeRegistry {
    enum Failure: Error {
        case typeNotRegistered(Any.Type)
    }

    struct Key: Hashable {
        let type: Any.Type

        init(type: Any.Type) {
            self.type = type
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(ObjectIdentifier(type))
        }

        static func ==(lhs: TypeRegistry.Key, rhs: TypeRegistry.Key) -> Bool {
            lhs.type == rhs.type
        }
    }

    private var registry = [TypeRegistry.Key: TypeFactory]()
    var messages: [String] = []

    deinit {
        AmplifyTesting.assign(instanceFactory: nil)
    }

    static func register<T>(type: T.Type, factory: @escaping (String?) -> T) -> TypeRegistry {
        let registry = TypeRegistry()
        registry.register(type: type, factory: factory)
        AmplifyTesting.assign(instanceFactory: registry)

        return registry
    }

    func register<T>(type: T.Type, factory: @escaping (String?) -> T) {
        registry[TypeRegistry.Key(type: type)] = { message in
            self.add(message: message)
            return factory(message)
        }
    }

    func add(message: String?) {
        messages.append(message ?? "")
    }

    func get<T>(type: T.Type, message: @autoclosure () -> String = String()) throws -> T {
        guard let factory = registry[TypeRegistry.Key(type: type)],
        let instance = factory(message()) as? T else {
            throw Failure.typeNotRegistered(type)
        }
        return instance
    }

    func reset() {
        registry.removeAll()
    }
}
