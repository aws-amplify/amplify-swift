//
//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A base PluginSelectorFactory class that can be extended to select the
/// appropriate plugins for categories with multiple plugins
public class BasePluginSelectorFactory<AssociatedCategory: Category>: PluginSelectorFactory {
//    public typealias PluginSelectorCategory = AssociatedCategory
//
//    var plugins = [PluginKey: PluginSelectorCategory.PluginType]()
//    var selectorClass: PluginSelectorClass.Type
//
//    required public init<Selector: PluginSelector>(selectorClass: Selector.Type) {
//        self.selectorClass = selectorClass
//    }
//
//    public func add(wrappedPlugin: PluginSelectorCategory.PluginType) {
//        plugins[wrappedPlugin.key] = wrappedPlugin
//    }
//
//    public func removePlugin(for key: PluginKey) {
//        plugins.removeValue(forKey: key)
//    }
//
//    public func makeSelector() -> PluginSelectorClass {
//        return PluginSelectorClass()
//    }

}
