//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Per AWS reference guide https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
/// URL querystring should be encoded according to the following rules:
/// - percent-encode with %XY (X and Y are hexadecimal characters) all characters
///   but any of the __unreserved characters__ defined by `RFC3986` (A-Za-z0-9-_.~)
/// - encode spaces with %20
/// - double encode any equals in params values
///
/// `URLComponents` encodes queryItems values by strictly following `RFC 3986`.
/// This function encode missing characters needed to make the querystring compliant to AWS guidelines
/// without double encoding those characters already encoded by `URLComponents`
extension URLComponents {
    static var sigV4UnreservedCharacters: CharacterSet = {
        var sigV4UnreservedCharacters = CharacterSet(charactersIn: "A" ... "Z")
        sigV4UnreservedCharacters = sigV4UnreservedCharacters.union(CharacterSet(charactersIn: "a" ... "z"))
        sigV4UnreservedCharacters = sigV4UnreservedCharacters.union(CharacterSet(charactersIn: "0" ... "9"))
        sigV4UnreservedCharacters = sigV4UnreservedCharacters.union(CharacterSet(charactersIn: "-_~."))
        return sigV4UnreservedCharacters
    }()

    private func encodeQueryParamItemBySigV4Rules(_ value: String) -> String {
        // removingPercentEncoding returns `nil` if called on a value
        // that hasn't been prior encoded
        let unencoded = value.removingPercentEncoding ?? value

        return unencoded.addingPercentEncoding(
            withAllowedCharacters: Self.sigV4UnreservedCharacters) ?? value
    }

    mutating func encodeQueryItemsPerSigV4Rules(_ queryItems: [String: String]?) {
        guard let queryItems = queryItems else {
            return
        }
        percentEncodedQuery = queryItems.map { name, value in
            let encodedName = encodeQueryParamItemBySigV4Rules(name)
            let encodedValue = encodeQueryParamItemBySigV4Rules(value)

            return [encodedName, encodedValue].joined(separator: "=")
        }.joined(separator: "&")
    }
}
