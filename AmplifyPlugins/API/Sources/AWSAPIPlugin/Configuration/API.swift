// this file is generated

public struct Backend {
    static var apiConfiguration: AWSAPIPluginConfiguration {
        return .init(apiName: "APIName",
                     endpoint: "http://endpoint",
                     endpointType: .graphQL,
                     region: "us-east-1",
                     authorizationType: .amazonCognitoUserPools)
    }
}

// Developer's code
import Amplify

func before() throws {
    let plugin = AWSAPIPlugin()
    try Amplify.add(plugin: plugin)
    try Amplify.configure()
}

func after() throws {
    let plugin: AWSAPIPlugin
    #if DEBUG
    plugin = AWSAPIPlugin(configuration: .dev)
    #else
    plugin = AWSAPIPlugin(configuration: .prod)
    #endif
    try Amplify.add(plugin: plugin)
    try Amplify.configure()
}

extension AWSAPIPluginConfiguration {
    static let prod: Self = .init(
        apiName: "APIName",
        endpoint: "http://endpoint",
        endpointType: .graphQL,
        region: "",
        authorizationType: .amazonCognitoUserPools
    )

    static let dev: Self = .init(
        apiName: "",
        endpoint: "",
        endpointType: .graphQL,
        region: "",
        authorizationType: .amazonCognitoUserPools
    )
}




