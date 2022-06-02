//
//  File.swift
//  
//
//  Created by Roy, Jithin on 6/7/22.
//

import Foundation

protocol LoginsMapProvider {

    var loginsMap: [String: String] { get }
}

struct UnAuthLoginsMapProvider: LoginsMapProvider {

    let loginsMap: [String: String] = [:]
}
