//
//  File.swift
//  
//
//  Created by Saultz, Ian on 11/2/23.
//

import Foundation


private let allowedForQuery = CharacterSet.alphanumerics.union(
    .init(charactersIn: "_-.~")
)

private let allowedForPath = CharacterSet.alphanumerics.union(
    .init(charactersIn: "/_-.~")
)

extension String {
    public func urlQueryEncoded() -> String {
        addingPercentEncoding(withAllowedCharacters: allowedForQuery) ?? self
    }

    public func urlPathEncoded() -> String {
        addingPercentEncoding(withAllowedCharacters: allowedForPath) ?? self
    }
}
