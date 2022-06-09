//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import SQLite

/// This is a temporary placeholder class to interface with the SQLiteLocalStorageAdapter
/// This class needs to be updated to support Codable queries that can decode into a PinpointEvent object
class AnalyticsEventSQLStorage: AnalyticsEventStorage {
    private let dbAdapter: SQLStorageProtocol
    
    /// Initializer
    /// - Parameter dbAdapter: a LocalStorageProtocol adapter
    init(dbAdapter: SQLStorageProtocol) {
        self.dbAdapter = dbAdapter
    }
    
    /// Create the Event and Dirty Event Tables
    func initializeStorage() throws {
        log.debug("Initializing storage")
        let createEventTableStatement = """
            CREATE TABLE IF NOT EXISTS Event (
            id TEXT NOT NULL,
            attributes BLOB NOT NULL,
            eventType TEXT NOT NULL,
            metrics BLOB NOT NULL,
            eventTimestamp TEXT NOT NULL,
            sessionId TEXT NOT NULL,
            sessionStartTime TEXT NOT NULL,
            sessionStopTime TEXT NOT NULL,
            timestamp REAL NOT NULL,
            dirty INTEGER NOT NULL,
            retryCount INTEGER NOT NULL)
        """
        let createDirtyEventTableStatement = """
            CREATE TABLE IF NOT EXISTS DirtyEvent (
            id TEXT NOT NULL,
            attributes BLOB NOT NULL,
            eventType TEXT NOT NULL,
            metrics BLOB NOT NULL,
            eventTimestamp TEXT NOT NULL,
            sessionId TEXT NOT NULL,
            sessionStartTime TEXT NOT NULL,
            sessionStopTime TEXT NOT NULL,
            timestamp REAL NOT NULL,
            dirty INTEGER NOT NULL,
            retryCount INTEGER NOT NULL)
        """

        do {
            try dbAdapter.createTable(createEventTableStatement)
            try dbAdapter.createTable(createDirtyEventTableStatement)
        } catch {
            log.error("Failed to create local storage table")
            throw LocalStorageError.invalidOperation(causedBy: error)
        }
    }
    
    /// Insert an Event into the Even table
    /// - Parameter bindings: a collection of values to insert into the Event
    func saveEvent(_ event: PinpointEvent) throws {
        let insertStatement = """
            INSERT INTO Event (
            id, attributes, eventType, metrics,
            eventTimestamp, sessionId, sessionStartTime,
            sessionStopTime, timestamp, dirty, retryCount)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        _ = try dbAdapter.executeQuery(insertStatement, event.getInsertBindings())
    }
    
    /// Delete all dirty events from the Event and DirtyEvent tables
    func deleteDirtyEvents() throws {
        let deleteFromDirtyEventTable = "DELETE FROM DirtyEvent"
        let deleteFromEventTable = "DELETE FROM Event WHERE dirty = 1"
        _ = try dbAdapter.executeQuery(deleteFromDirtyEventTable, [])
        _ = try dbAdapter.executeQuery(deleteFromEventTable, [])
    }
    
    /// Delete the oldest event from the Event table
    func deleteOldestEvent() throws {
        let deleteStatements = """
        DELETE FROM Event
        WHERE id IN (
        SELECT id
        FROM Event
        ORDER BY timestamp ASC
        LIMIT 1)
        """
        _ = try dbAdapter.executeQuery(deleteStatements, [])
    }
    
    /// Delete all events from the Event table
    func deleteAllEvents() throws {
        let deleteStatement = "DELETE FROM Event"
        _ = try dbAdapter.executeQuery(deleteStatement, [])
    }
    
    /// Get the oldest event with limit
    /// - Parameter limit: The number of query result to limit
    /// - Returns: A collection of PinpointEvent
    func getEventsWith(limit: Int) throws -> [PinpointEvent] {
        let queryStatement = """
        SELECT id, attributes, eventType, metrics, eventTimestamp, sessionId, sessionStartTime, sessionStopTime, timestamp, retryCount
        FROM Event
        ORDER BY timestamp ASC
        LIMIT ?
        """
        let rows = try dbAdapter.executeQuery(queryStatement, [limit])
        var result = [PinpointEvent]()
        for element in rows {
            if let event = PinpointEvent.convertToEvent(element) {
                result.append(event)
            }
        }
        return result
    }
    
    /// Get the oldest dirty events with limit
    /// - Parameter limit: The number of query result to limit
    /// - Returns: A collection of PinpointEvent
    func getDirtyEventsWith(limit: Int) throws -> [PinpointEvent] {
        let queryStatement = """
        SELECT id, attributes, eventType, metrics, eventTimestamp, sessionId, sessionStartTime, sessionStopTime, timestamp, retryCount
        FROM DirtyEvent
        ORDER BY timestamp ASC
        LIMIT ?
        """
        let rows = try dbAdapter.executeQuery(queryStatement, [limit])
        var result = [PinpointEvent]()
        for element in rows {
            if let event = PinpointEvent.convertToEvent(element) {
                result.append(event)
            }
        }
        return result
    }
    
    /// Set the dirty column to 1 for the event in the Event table
    /// - Parameter eventId: The event id for the event to update
    func setDirtyEvent(eventId: String) throws {
        let updateStatement = """
            UPDATE Event SET dirty = 1 WHERE id = ?
        """
        _ = try dbAdapter.executeQuery(updateStatement, [eventId])
    }
    
    /// Increment the retry count on the event in the event table by 1
    /// - Parameter eventId: The event id for the event to update
    func incrementEventRetry(eventId: String) throws {
        let updateStatement = """
        UPDATE Event SET retryCount = retryCount + 1 WHERE id = ?
        """
        _ = try dbAdapter.executeQuery(updateStatement, [eventId])
    }
    
    /// Delete the event in the Event table
    /// - Parameter eventId: The event id for the event to delete
    func deleteEvent(eventId: String) throws {
        let deleteStatement = """
        DELETE FROM Event WHERE id = ?
        """
        _ = try dbAdapter.executeQuery(deleteStatement, [eventId])
    }
    
    /// Set the dirty column to 1 for the event
    /// Move the dirty event to the DirtyEvent table
    /// Delete the dirty evetn from the Event table
    /// - Parameter eventId: The event id for the event to update
    func removeFailedEvents() throws {
        let markStatement = """
        UPDATE Event
        SET dirty = 1
        WHERE retryCount > 3
        """
        
        let moveStatement = """
        INSERT INTO DirtyEvent
        SELECT * FROM Event
        WHERE dirty = 1
        """
        
        let deleteStatement = """
        DELETE FROM Event
        WHERE dirty = 1
        """
        _ = try dbAdapter.executeQuery(markStatement, [])
        _ = try dbAdapter.executeQuery(moveStatement, [])
        _ = try dbAdapter.executeQuery(deleteStatement, [])
    }
    
    /// Check the disk usage limit of the local database.
    /// If database is over the limit then delete all dirty events and oldest event 
    /// - Parameter byteLimit: the size limit of the database
    func checkDiskSize(byteLimit: Int) throws {
        if dbAdapter.diskByteUsed > byteLimit {
            try self.deleteDirtyEvents()
        }
        
        if dbAdapter.diskByteUsed > byteLimit {
            try self.deleteOldestEvent()
        }
    }
}

extension AnalyticsEventSQLStorage: DefaultLogger { }
