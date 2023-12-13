//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AmplifyConfiguration {
    init(bundle: Bundle, withOverride configuration: AmplifyConfiguration? = nil) throws {
        guard let path = bundle.path(forResource: "amplifyconfiguration", ofType: "json") else {
            
            if let configuration = configuration {
                self = configuration
                return
            }
            
            throw ConfigurationError.invalidAmplifyConfigurationFile(
                """
                Could not load default `amplifyconfiguration.json` file
                """,

                """
                Expected to find the file, `amplifyconfiguration.json` in the app bundle at `\(bundle.bundlePath)`, but
                it was not present. Either add amplifyconfiguration.json to your app's "Copy Bundle Resources" build
                phase, or invoke `Amplify.configure()` with a configuration object that you load from a custom path.
                """
            )
        }

        let url = URL(fileURLWithPath: path)
        self = try AmplifyConfiguration.loadAmplifyConfiguration(from: url, withOverride: configuration)
    }

    static func loadAmplifyConfiguration(from url: URL, withOverride configuration: AmplifyConfiguration? = nil) throws -> AmplifyConfiguration {
        let fileData: Data
        do {
            fileData = try Data(contentsOf: url)
        } catch {
            throw ConfigurationError.invalidAmplifyConfigurationFile(
                """
                Could not extract UTF-8 data from `\(url.path)`
                """,

                """
                Could not load data from the file at `\(url.path)`. Inspect the file to ensure it is present.
                The system reported the following error:
                \(error.localizedDescription)
                """,
                error
            )
        }

        var decodedConfiguration = try decodeAmplifyConfiguration(from: fileData)
        if let configuration = configuration {
            // Got both `configuration` and `configurationFromBundle`, merge the configuration here.
            
            // The logic is two parts- merge and overwrite. Overwrite matters depending on which configuration is modified
            // if the `configurationFromBundle` is modified with the in-memory configuration, then the in-memory configuration
            // overwrites keys in the configuration from bundle, thus, the in-memory config takes precedent over the
            // configuration file.
                
            configuration.analytics?.plugins.forEach({ (pluginKey, config) in
                decodedConfiguration.analytics?.plugins.updateValue(config, forKey: pluginKey)
            })
            
            configuration.api?.plugins.forEach({ (pluginKey, config) in
                decodedConfiguration.api?.plugins.updateValue(config, forKey: pluginKey)
            })
            
            configuration.auth?.plugins.forEach({ (pluginKey, config) in
                decodedConfiguration.auth?.plugins.updateValue(config, forKey: pluginKey)
            })
            
            configuration.dataStore?.plugins.forEach({ (pluginKey, config) in
                decodedConfiguration.dataStore?.plugins.updateValue(config, forKey: pluginKey)
            })
            
            configuration.geo?.plugins.forEach({ (pluginKey, config) in
                decodedConfiguration.geo?.plugins.updateValue(config, forKey: pluginKey)
            })
            
            configuration.hub?.plugins.forEach({ (pluginKey, config) in
                decodedConfiguration.hub?.plugins.updateValue(config, forKey: pluginKey)
            })
            
            configuration.logging?.plugins.forEach({ (pluginKey, config) in
                decodedConfiguration.logging?.plugins.updateValue(config, forKey: pluginKey)
            })
            
            configuration.notifications?.plugins.forEach({ (pluginKey, config) in
                decodedConfiguration.notifications?.plugins.updateValue(config, forKey: pluginKey)
            })
            
            configuration.predictions?.plugins.forEach({ (pluginKey, config) in
                decodedConfiguration.predictions?.plugins.updateValue(config, forKey: pluginKey)
            })
            
            configuration.storage?.plugins.forEach({ (pluginKey, config) in
                decodedConfiguration.storage?.plugins.updateValue(config, forKey: pluginKey)
            })
        }
        return decodedConfiguration
    }

    static func decodeAmplifyConfiguration(from data: Data) throws -> AmplifyConfiguration {
        let jsonDecoder = JSONDecoder()

        do {
            let configuration = try jsonDecoder.decode(AmplifyConfiguration.self, from: data)
            return configuration
        } catch {
            throw ConfigurationError.unableToDecode(
                """
                Could not decode `amplifyconfiguration.json` into a valid AmplifyConfiguration object
                """,

                """
                `amplifyconfiguration.json` was found, but could not be converted to an AmplifyConfiguration object
                using the default JSONDecoder. The system reported the following error:
                \(error.localizedDescription)
                """,
                error
            )
        }
    }

}
