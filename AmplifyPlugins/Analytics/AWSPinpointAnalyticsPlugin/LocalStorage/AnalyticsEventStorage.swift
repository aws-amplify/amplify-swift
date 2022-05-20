//
//  File.swift
//  
//
//  Created by Pham, Tuan on 5/18/22.
//

import Foundation

protocol AnalyticsEventStorage {
    func initializeStorage() throws
    func deleteOldestEvent() throws
    func deleteAllEvents() throws
}
