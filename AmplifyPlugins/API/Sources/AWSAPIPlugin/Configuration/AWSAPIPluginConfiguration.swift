import Foundation
import AWSPluginsCore

public struct AWSAPIPluginConfiguration: Codable {
    
    public struct API: Codable {
        var apiName: String
        var endpoint: String
        var endpointType: AWSAPIPluginEndpointType
        var region: String
        var authorizationType: AWSAuthorizationType
        var apiKey: String?
    }
    
    public let apis: [API]
    
    public init(apiName: String = UUID().uuidString,
                endpoint: String,
                endpointType: AWSAPIPluginEndpointType,
                region: String,
                authorizationType: AWSAuthorizationType,
                apiKey: String? = nil) {
        self.apis = [.init(apiName: apiName,
                           endpoint: endpoint,
                           endpointType: endpointType,
                           region: region,
                           authorizationType: authorizationType)]
    }
    
    public init(_ apis: API...) {
        self.apis = apis
    }
}
