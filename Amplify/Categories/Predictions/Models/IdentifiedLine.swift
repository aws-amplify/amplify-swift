//
//  IdentifiedLine.swift
//  Amplify
//
//  Created by Stone, Nicki on 11/14/19.
//

import Foundation

public struct IdentifiedLine: SyntacticalStructure {
    
    var text: String
    var boundingBox: BoundingBox
    var polygon: Polygon
    var page: Int?
    
    public init(text: String, boundingBox: BoundingBox, polygon: Polygon, page: Int? = nil){
        self.text = text
        self.boundingBox = boundingBox
        self.polygon = polygon
        self.page = page
    }
}
