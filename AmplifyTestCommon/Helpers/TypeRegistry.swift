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

class TypeRegistry {
    enum Failure: Error {
        case typeNotRegistered(Any.Type)
    }

    private var registry = [TypeKey: TypeFactory]()

    func register<T>(type: T.Type, factory: @escaping (String?) -> T) {
        registry[TypeKey(type: type)] = factory
    }

    func get<T>(type: T.Type, message: @autoclosure () -> String = String()) throws -> T {
        guard let factory = registry[TypeKey(type: type)],
        let instance = factory(message()) as? T else {
            throw Failure.typeNotRegistered(type)
        }
        return instance
    }

    func reset() {
        registry.removeAll()
    }
}
