//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSS3

public class AWSS3StoragePlugin : StorageCategoryPlugin {
    
    private let queue: OperationQueue = OperationQueue()
    
    public init() {
        
    }
    
    public var key: PluginKey {
        return "AWSS3StoragePlugin"
    }
    
    public func configure(using configuration: Any) throws {
        if let configuration = configuration as? [String: Any] {
            let bucket = configuration["Bucket"] as! String
            let region = configuration["Region"] as! String
            let credentialsProvider = configuration["CredentialsProvider"] as! [String:Any]
            let poolId = credentialsProvider["PoolId"] as! String
            let credentialsProviderRegion = credentialsProvider["Region"] as! String
            
            let credentialProvider = AWSCognitoCredentialsProvider(regionType: credentialsProviderRegion.aws_regionTypeValue(), identityPoolId: poolId)
            let serviceConfiguration: AWSServiceConfiguration = AWSServiceConfiguration(region: region.aws_regionTypeValue(), credentialsProvider: credentialProvider)
        
            AWSS3TransferUtility.register(with: serviceConfiguration, forKey: key)
            AWSS3PreSignedURLBuilder.register(with: serviceConfiguration, forKey: key)
            AWSS3.register(with: serviceConfiguration, forKey: key)
        }
    }
    
    public func reset() {
    }
    

    public func get(key: String, options: Any?) -> StorageGetOperation {
        let operation = AWSS3StorageGetOperation(key: key)
        queue.addOperation(operation)
        return operation
    }
    
    public func stub() {
    }
}
