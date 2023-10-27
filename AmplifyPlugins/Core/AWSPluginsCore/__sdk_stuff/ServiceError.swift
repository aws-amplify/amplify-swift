//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/27/23.
//

import Foundation

// Placeholder Error
public struct ServiceError: Error {
    public let message: String?
    public let type: String?
    public let httpURLResponse: HTTPURLResponse

    public init(
        message: String?,
        type: String?,
        httpURLResponse: HTTPURLResponse
    ) {
        self.message = message
        self.type = type
        self.httpURLResponse = httpURLResponse
    }
}
