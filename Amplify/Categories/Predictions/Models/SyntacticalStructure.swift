//
//  SyntacticalStructure.swift
//  Amplify
//
//  Created by Stone, Nicki on 11/14/19.
//

import Foundation

protocol SyntacticalStructure {
    var text: String { get }
    var boundingBox: BoundingBox { get }
    var polygon: Polygon { get }
    var page: Int? { get set }
}
