//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
// import ClientRuntime


struct EndpointResolving {
    let run: (String) throws -> Endpoint
}

extension EndpointResolving {
    private static func validate<T, U>(
        _ input: T,
        with validationStep: ValidationStep<T, U>
    ) throws -> U {
        try validationStep.validate(input)
    }

    static let userPool = EndpointResolving { endpoint in
        // We want to enforce that the endpoint is excluded from the
        // configuration so as not to give the impression that other
        // schemes are supported. While we could check for, and allow,
        // explicit `https` input as a convenience, that would provide
        // two valid paths and be an unnecessary source of confusion.
        // So we're going to fail if any scheme is included
        // in the configuration.
        try validate(endpoint, with: .schemeIsEmpty())

        // Next let's prepend the https scheme and confirm that the url
        // itself is valid. If not, we'll throw an error.
        let (components, host) = try validate(endpoint, with: .validURL())

        // Finally, let's confirm that the endpoint doesn't contain a path.
        try validate((components, endpoint), with: .pathIsEmpty())

        return Endpoint(host: host)
    }
}

struct PlaceholderError: Error {}

enum ProtocolType: String, CaseIterable {
    case http
    case https
}

struct Endpoint: Hashable {
    let path: String
    let queryItems: [URLQueryItem]?
    let protocolType: ProtocolType?
    let host: String
    let port: Int16
    let headers: Headers?
    let properties: [String: AnyHashable]

    init(urlString: String,
         headers: Headers? = nil,
         properties: [String: AnyHashable] = [:]) throws {
        guard let url = URL(string: urlString) else {
            throw PlaceholderError()
        }

        try self.init(url: url, headers: headers, properties: properties)
    }

    init(url: URL,
         headers: Headers? = nil,
         properties: [String: AnyHashable] = [:]) throws {
        guard let host = url.host else {
            throw PlaceholderError()
        }

        self.init(host: host,
                  path: url.path,
                  port: Int16(url.port ?? 443),
                  queryItems: url.toQueryItems(),
                  protocolType: ProtocolType(rawValue: url.scheme ?? ProtocolType.https.rawValue),
                  headers: headers,
                  properties: properties)
    }

    init(host: String,
         path: String = "/",
         port: Int16 = 443,
         queryItems: [URLQueryItem]? = nil,
         protocolType: ProtocolType? = .https,
         headers: Headers? = nil,
         properties: [String: AnyHashable] = [:]) {
        self.host = host
        self.path = path
        self.port = port
        self.queryItems = queryItems
        self.protocolType = protocolType
        self.headers = headers
        self.properties = properties
    }
}

extension URL {

    func toQueryItems() -> [URLQueryItem]? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .map { URLQueryItem(name: $0.name, value: $0.value) }
    }
}

extension Endpoint {
    // We still have to keep 'url' as an optional, since we're
    // dealing with dynamic components that could be invalid.
    var url: URL? {
        var components = URLComponents()
        components.scheme = protocolType?.rawValue
        components.host = host
        components.percentEncodedPath = path
        components.percentEncodedQuery = queryItemString
        return components.url
    }

    var queryItemString: String? {
        guard let queryItems = queryItems else { return nil }
        return queryItems.map { queryItem in
            return [queryItem.name, queryItem.value].compactMap { $0 }.joined(separator: "=")
        }.joined(separator: "&")
    }
}

// TODO: Remove in favor of a Dictionary or KeyValuePair
public struct Headers {
    public var headers: [Header] = []

    /// Creates an empty instance.
    public init() {}

    /// Creates an instance from a `[String: String]`. Duplicate case-insensitive names are collapsed into the last name
    /// and value encountered.
    public init(_ dictionary: [String: String]) {
        self.init()

        dictionary.forEach { add(name: $0.key, value: $0.value)}
    }

    /// Creates an instance from a `[String: [String]]`.
    public init(_ dictionary: [String: [String]]) {
        self.init()

        dictionary.forEach { key, values in add(name: key, values: values) }
    }

    /// Case-insensitively updates or appends a `Header` into the instance using the provided `name` and `value`.
    ///
    /// - Parameters:
    ///   - name:  The `String` name.
    ///   - value: The `String` value.
    public mutating func add(name: String, value: String) {
        let header = Header(name: name, value: value)
        add(header)
    }

    /// Case-insensitively updates the value of a `Header` by appending the new values to it or appends a `Header`
    /// into the instance using the provided `name` and `values`.
    ///
    /// - Parameters:
    ///   - name:  The `String` name.
    ///   - values: The `[String]` values.
    public mutating func add(name: String, values: [String]) {
        let header = Header(name: name, values: values)
        add(header)
    }

    /// Case-insensitively updates the value of a `Header` by appending the new values to it or appends a `Header`
    /// into the instance using the provided `Header`.
    ///
    /// - Parameters:
    ///   - header:  The `Header` to be added or updated.
    public mutating func add(_ header: Header) {
        guard let index = headers.index(of: header.name) else {
            headers.append(header)
            return
        }
        headers[index].value.append(contentsOf: header.value)
    }

    /// Case-insensitively updates the value of a `Header` by replacing the values of it or appends a `Header`
    /// into the instance if it does not exist using the provided `Header`.
    ///
    /// - Parameters:
    ///   - header:  The `Header` to be added or updated.
    public mutating func update(_ header: Header) {
        guard let index = headers.index(of: header.name) else {
            headers.append(header)
            return
        }
        headers.replaceSubrange(index...index, with: [header])
    }

    /// Case-insensitively updates the value of a `Header` by replacing the values of it or appends a `Header`
    /// into the instance if it does not exist using the provided `Header`.
    ///
    /// - Parameters:
    ///   - header:  The `Header` to be added or updated.
    public mutating func update(name: String, value: [String]) {
        let header = Header(name: name, values: value)
        update(header)
    }

    /// Case-insensitively updates the value of a `Header` by replacing the values of it or appends a `Header`
    /// into the instance if it does not exist using the provided `Header`.
    ///
    /// - Parameters:
    ///   - header:  The `Header` to be added or updated.
    public mutating func update(name: String, value: String) {
        let header = Header(name: name, value: value)
        update(header)
    }

    /// Case-insensitively adds all `Headers` into the instance using the provided `[Headers]` array.
    ///
    /// - Parameters:
    ///   - headers:  The `Headers` object.
    public mutating func addAll(headers: Headers) {
        self.headers.append(contentsOf: headers.headers)
    }

    /// Case-insensitively removes a `Header`, if it exists, from the instance.
    ///
    /// - Parameter name: The name of the `HTTPHeader` to remove.
    public mutating func remove(name: String) {
        guard let index = headers.index(of: name) else { return }

        headers.remove(at: index)
    }

    /// Case-insensitively find a header's values by name.
    ///
    /// - Parameter name: The name of the header to search for, case-insensitively.
    ///
    /// - Returns: The values of the header, if they exist.
    public func values(for name: String) -> [String]? {
        guard let indices = headers.indices(of: name), !indices.isEmpty else { return nil }
        var values = [String]()
        for index in indices {
            values.append(contentsOf: headers[index].value)
        }

        return values
    }

    /// Case-insensitively find a header's value by name.
    ///
    /// - Parameter name: The name of the header to search for, case-insensitively.
    ///
    /// - Returns: The value of header as a comma delimited string, if it exists.
    public func value(for name: String) -> String? {
        guard let values = values(for: name) else {
            return nil
        }
        return values.joined(separator: ",")
    }

    public func exists(name: String) -> Bool {
        guard headers.index(of: name) != nil else {
            return false
        }

        guard let value = value(for: name) else {
            return false
        }

        return !value.isEmpty
    }

    /// The dictionary representation of all headers.
    ///
    /// This representation does not preserve the current order of the instance.
    public var dictionary: [String: [String]] {
        let namesAndValues = headers.map { ($0.name, $0.value) }

        return Dictionary(namesAndValues) { (first, last) -> [String] in
            return first + last
        }
    }
}

extension Headers: Equatable {
    /// Returns a boolean value indicating whether two values are equal irrespective of order.
    /// - Parameters:
    ///   - lhs: The first `Headers` to compare.
    ///   - rhs: The second `Headers` to compare.
    /// - Returns: `true` if the two values are equal irrespective of order, otherwise `false`.
    public static func == (lhs: Headers, rhs: Headers) -> Bool {
        return lhs.headers.sorted() == rhs.headers.sorted()
    }
}

extension Headers: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(headers.sorted())
    }
}

extension Array where Element == Header {
    /// Case-insensitively finds the index of an `Header` with the provided name, if it exists.
    func index(of name: String) -> Int? {
        let lowercasedName = name.lowercased()
        return firstIndex { $0.name.lowercased() == lowercasedName }
    }

    /// Case-insensitively finds the indexes of an `Header` with the provided name, if it exists.
    func indices(of name: String) -> [Int]? {
        let lowercasedName = name.lowercased()
        return enumerated().compactMap { $0.element.name.lowercased() == lowercasedName ? $0.offset : nil }
    }
}

public struct Header {
    public var name: String
    public var value: [String]

    public init(name: String, values: [String]) {
        self.name = name
        self.value = values
    }

    public init(name: String, value: String) {
        self.name = name
        self.value = [value]
    }
}

extension Header: Equatable {
    public static func == (lhs: Header, rhs: Header) -> Bool {
        return lhs.name == rhs.name && lhs.value.sorted() == rhs.value.sorted()
    }
}

extension Header: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(value.sorted())
    }
}

extension Header: Comparable {
    /// Compares two `Header` instances by name.
    /// - Parameters:
    ///  - lhs: The first `Header` to compare.
    /// - rhs: The second `Header` to compare.
    /// - Returns: `true` if the first `Header`'s name is less than the second `Header`'s name, otherwise `false`.
    public static func < (lhs: Header, rhs: Header) -> Bool {
        return lhs.name < rhs.name
    }
}

//extension Headers {
//    func toHttpHeaders() -> [HTTPHeader] {
//        headers.map {
//            HTTPHeader(name: $0.name, value: $0.value.joined(separator: ","))
//        }
//    }
//
//    init(httpHeaders: [HTTPHeader]) {
//        self.init()
//        addAll(httpHeaders: httpHeaders)
//    }
//
//    public mutating func addAll(httpHeaders: [HTTPHeader]) {
//        httpHeaders.forEach {
//            add(name: $0.name, value: $0.value)
//        }
//    }
//}

extension Headers: CustomDebugStringConvertible {
    public var debugDescription: String {
        return dictionary.map {"\($0.key): \($0.value.joined(separator: ", "))"}.joined(separator: ", \n")
    }
}
