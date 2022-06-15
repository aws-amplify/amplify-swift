//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol AnalyticsEventStorage {
  /// Delete the event in the Event table
  /// - Parameter eventId: The event id for the event to delete
  func deleteEvent(eventId: String) throws
  /// Delete all dirty events from the Event and DirtyEvent tables
  func deleteDirtyEvents() throws
  /// Create the Event and Dirty Event Tables
  func initializeStorage() throws
  /// Delete the oldest event from the Event table
  func deleteOldestEvent() throws
  /// Delete all events from the Event table
  func deleteAllEvents() throws
  /// Get the oldest event with limit
  /// - Parameter limit: The number of query result to limit
  /// - Returns: A collection of PinpointEvent
  func getEventsWith(limit: Int) throws -> [PinpointEvent]
  /// Increment the retry count on the event in the event table by 1
  /// - Parameter eventId: The event id for the event to update
  func incrementEventRetry(eventId: String) throws
  /// Set the dirty column to 1 for the event
  /// Move the dirty event to the DirtyEvent table
  /// Delete the dirty evetn from the Event table
  /// - Parameter eventId: The event id for the event to update
  func removeFailedEvents() throws
  /// Insert an Event into the Even table
  /// - Parameter bindings: a collection of values to insert into the Event
  func saveEvent(_ event: PinpointEvent) throws
  /// Set the dirty column to 1 for the event in the Event table
  /// - Parameter eventId: The event id for the event to update
  func setDirtyEvent(eventId: String) throws

  /// Checks to see if local storage size is over the limit
  /// - Parameter limit: the Byte limit of the local storage
  func checkDiskSize(limit: Byte) throws
}
