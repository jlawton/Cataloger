//
//  Result+Errors.swift
//  cataloger
//
//  Created by James Lawton on 10/24/19.
//  Copyright © 2019 James Lawton. All rights reserved.
//

import Foundation

extension Result {
    var error: Failure? {
        switch self {
        case .success:
            return nil
        case let .failure(error):
            return error
        }
    }
}

/// Represents the absence of errors.
enum NoError: Error {
}

/// Protocol used to constrain `tryMap` to `Result`s with compatible `Error`s.
public protocol ErrorProtocolConvertible: Error {
    static func error(from error: Error) -> Self
}

extension Result where Failure: ErrorProtocolConvertible {
    /// Returns the result of applying `transform` to `Success`es’ values, or wrapping thrown errors.
    func tryMap<U>(_ transform: (Success) throws -> U) -> Result<U, Failure> {
        return flatMap { value in
            do {
                return .success(try transform(value))
            }
            catch {
                let convertedError = Failure.error(from: error)
                return .failure(convertedError)
            }
        }
    }
}
