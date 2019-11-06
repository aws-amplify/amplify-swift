//
//  AWSAppSyncAuthProvider.swift
//  AWSAppSync
//

// For using OIDC based authorization, this protocol needs to be implemented and passed to configuration object.
// Use this for cases where the OIDC token needs to be fetched asynchronously and requires a callback
public protocol AWSOIDCAuthProviderAsync: AWSOIDCAuthProvider {
    func getLatestAuthToken(_ callback: @escaping (String?, Error?) -> Void)
}

// For AuthProviders that use a callback, the getLatestAuthToken is defaulted to return an empty string
extension AWSOIDCAuthProviderAsync {
    public func getLatestAuthToken() -> String { fatalError("Callback method required") }
}

// For using User Pool based authorization, this protocol needs to be implemented and passed to configuration object.
// Use this for cases where the UserPool auth token needs to be fetched asynchronously and requires a callback
public protocol AWSCognitoUserPoolsAuthProviderAsync: AWSCognitoUserPoolsAuthProvider {
    func getLatestAuthToken(_ callback: @escaping (String?, Error?) -> Void)
}

// For CognitoUserPoolAuthProviders that use a callback, the getLatestAuthToken is defaulted to return an empty string
extension AWSCognitoUserPoolsAuthProviderAsync {
    public func getLatestAuthToken() -> String { fatalError("Callback method required") }
}

// For using OIDC based authorization, this protocol needs to be implemented and passed to configuration object.
public protocol AWSOIDCAuthProvider {
    /// The method should fetch the token and return it to the client for using in header request.
    func getLatestAuthToken() -> String
}

// For using Cognito User Pools based authorization, this protocol needs to be implemented and passed to configuration object.
public protocol AWSCognitoUserPoolsAuthProvider: AWSOIDCAuthProvider {

}

// For using API Key based authorization, this protocol needs to be implemented and passed to configuration object.
public protocol AWSAPIKeyAuthProvider {
    func getAPIKey() -> String
}
