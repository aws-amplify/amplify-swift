//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A Tree data type with a `value` of some type `E` and `children` subtrees.
public class Tree<E> {

    /// <#Description#>
    public var value: E

    /// <#Description#>
    public var children: [Tree<E>] = []

    /// <#Description#>
    public weak var parent: Tree<E>?

    /// <#Description#>
    /// - Parameter value: <#value description#>
    public init(value: E) {
        self.value = value
    }

    /// Add a child to the tree's children and set a weak reference from the child to the parent (`self`)
    public func addChild(settingParentOf child: Tree) {
        children.append(child)
        child.parent = self
    }
}
