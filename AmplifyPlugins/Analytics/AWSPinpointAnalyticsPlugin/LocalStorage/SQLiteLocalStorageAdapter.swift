//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite

/// Local storage adapter that implements local storage using SQLite.swift
final class SQLiteLocalStorageAdapter: SQLStorageProtocol {
  private var connection: Connection?
  private var dbFilePath: URL?
  private let fileManager: FileManagerBehaviour
  var diskBytesUsed: Byte {
    guard let url = dbFilePath else { return 0 }
    return fileManager.fileSize(for: url)
  }

  /// Initializer
  /// - Parameter databaseName: The database name
  convenience init(prefixPath: String = "", databaseName: String) throws {
    var dbFilePath = SQLiteLocalStorageAdapter.getDbFilePath(
      prefixPath: prefixPath, databaseName: databaseName)
    let connection: Connection
    do {
      connection = try Connection(dbFilePath.absoluteString)
      var urlResourceValues = URLResourceValues()
      urlResourceValues.isExcludedFromBackup = true
      try dbFilePath.setResourceValues(urlResourceValues)
    } catch {
      throw LocalStorageError.invalidStorage(path: dbFilePath.absoluteString, error)
    }

    try self.init(connection: connection, dbFilePath: dbFilePath)
  }

  /// Initializer
  /// - Parameters:
  ///   - connection: SQLite Connection
  ///   - dbFilePath: Path to the database
  private init(
    connection: Connection,
    dbFilePath: URL? = nil,
    fileManager: FileManagerBehaviour = FileManager.default
  ) throws {
    self.connection = connection
    self.dbFilePath = dbFilePath
    self.fileManager = fileManager
    try initializeDatabase(connection: connection)
  }

  /// Initilizes the database and create the table if it doesn't already exists
  /// - Parameter connection: SQLite connection
  private func initializeDatabase(connection: Connection) throws {
    log.debug("Initializing database connection: \(String(describing: connection))")
    let databaseInitializationStatement = """
      pragma auto_vacuum = full;
      pragma encoding = "utf-8";
      pragma foreign_keys = on;
      pragma case_sensitive_like = off;
      """

    try connection.execute(databaseInitializationStatement)
  }

  /// Get the database file path constructed by the database name and the Documents directory
  /// - Parameter databaseName: The database file name
  /// - Returns: URL containing the location of the database
  internal static func getDbFilePath(prefixPath: String = "", databaseName: String) -> URL {
    guard let documentsPath = getDocumentPath() else {
      preconditionFailure("Could not create the database. The `.documentDirectory` is invalid")
    }
    return documentsPath.appendingPathComponent(prefixPath).appendingPathComponent(
      "\(databaseName).db")
  }

  /// Get document path
  /// - Returns: Optional URL to the Document path
  private static func getDocumentPath() -> URL? {
    return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
  }

  /// Create a SQL table
  /// - Parameter statement: SQL statement to create a table
  func createTable(_ statement: String) throws {
    guard let connection = connection else {
      throw LocalStorageError.missingConnection
    }

    do {
      try connection.execute(statement)
    } catch {
      throw LocalStorageError.invalidOperation(causedBy: error)
    }
  }

  /// Executes a SQL query
  /// - Parameters:
  ///   - statement: SQL query statement
  ///   - bindings: A collection of SQL bindings to prepare with the query statement
  /// - Returns: A SQL statement result from the query
  func executeQuery(_ statement: String, _ bindings: [Binding?]) throws -> Statement {
    guard let connection = connection else {
      throw LocalStorageError.missingConnection
    }

    do {
      let statement = try connection.prepare(statement).run(bindings)
      return statement
    } catch {
      throw LocalStorageError.invalidOperation(causedBy: error)
    }
  }
}

extension SQLiteLocalStorageAdapter: DefaultLogger {}
