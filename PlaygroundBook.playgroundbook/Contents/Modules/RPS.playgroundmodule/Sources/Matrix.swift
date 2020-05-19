//
//  Matrix.swift
//  RPS
//
//  Created by Minhyuk Kim on 2020/05/09.
//

import Foundation

public typealias Vector<T : Hashable> = [T : Int]
public typealias Matrix<T : Hashable> = [T : Vector<T>]
public typealias DoubleMatrix<T: Hashable> = [T: Matrix<T>]

public extension Matrix where Value == Vector<Key> {
    /// Given a current state, this method returns the probabilities of the next state.
    ///
    /// - Parameter given: The current state.
    /// - Returns: A dictionary of the probabilities, where the states are the keys and the values
    ///        are the probability from the current state.
    ///
    /// - Complexity: O(1), regardless the matrix's size.
    func probabilities(given: Key) -> Vector<Key> {
        return self[given] ?? [:]
    }
    
    /// Given a current state, this method returns the next state, based on an input criteria.
    ///
    /// - Parameters:
    ///   - given: The current state
    ///   - process: The decision process to calculate the next state.
    /// - Returns: The calculated next state.
    ///
    /// - Complexity: O(n), where *n* is the length of the possible transitions
    ///        for the given **states**.
    func next(given: Key) -> Key? {
        guard let values = self[given] else {
            return nil
        }
        
        return values.max(by: { $0.value < $1.value })?.key
    }
    
    func appendTransitionsMatrix(currentMatrix: Matrix<Key>) -> Matrix<Key> {
        var matrix = currentMatrix
        
        self.forEach({ key, value in
            if var currentChain = matrix[key] {
                value.forEach({ innerKey, count in
                    currentChain[innerKey] = count + (currentChain[innerKey] ?? 0)
                })
            } else {
                matrix[key] = value
            }
        })
        
        return matrix
    }
    
}

public extension DoubleMatrix where Value == Matrix<Key> {
    /// Given a current state, this method returns the probabilities of the next state.
    ///
    /// - Parameter given: The current state.
    /// - Returns: A dictionary of the probabilities, where the states are the keys and the values
    ///        are the probability from the current state.
    ///
    /// - Complexity: O(1), regardless the matrix's size.
    func probabilities(given: (first: Key, second: Key)) -> Vector<Key> {
        return self[given.first]?[given.second] ?? [:]
    }
    
    /// Given a current state, this method returns the next state, based on an input criteria.
    ///
    /// - Parameters:
    ///   - given: The current state
    ///   - process: The decision process to calculate the next state.
    /// - Returns: The calculated next state.
    ///
    /// - Complexity: O(n), where *n* is the length of the possible transitions
    ///        for the given **states**.
    func next(given: (first: Key, second: Key)) -> Key? {
        guard let values = self[given.first]?[given.second] else {
            return nil
        }
        
        return values.max(by: { $0.value < $1.value })?.key
    }
}

extension Array where Element : Hashable {
    /// Builds up a states transition matrix based on an array of state transitions.
    /// The data structure is represented in a bi-dimensional dictionary where keys represent
    /// the `from` and `to` states.
    ///
    /// - Parameters:
    ///   - states: An ordered collection of states. They represent both coulmns and rows.
    ///
    /// - Complexity: O(n), where **n** is the total length of all transitions.
    func makeTransitionsMatrix() -> Matrix<Element> {
        
        var changesMatrix = Matrix<Element>()

        guard var old = first else {
            return changesMatrix
        }

        suffix(from: 1).forEach { nextValue in
            var chain = changesMatrix[old] ?? Vector<Element>()
            chain[nextValue, default: 0] += 1
            changesMatrix[old] = chain
            old = nextValue
        }
        
        return changesMatrix
    }
    
    func appendTransitionsMatrix(currentMatrix: Matrix<Element>) -> Matrix<Element> {
        var matrix = currentMatrix
        guard var old = first else {
            return matrix
        }
        
        suffix(from: 1).forEach { nextValue in
            var chain = matrix[old] ?? Vector<Element>()
            chain[nextValue, default: 0] += 1
            matrix[old] = chain
            old = nextValue
        }
        
        return matrix
    }
    
    func makeTransitionsDoubleMatrix() -> DoubleMatrix<Element> {
        var changesMatrix = DoubleMatrix<Element>()

        guard var previousKey = self.first, var nextKey = self[exists: 1] else {
            return changesMatrix
        }
        
        for key in self.suffix(from: 2) {
            if let matrix = changesMatrix[previousKey] {
                var chain = matrix[nextKey] ?? Vector<Element>()
                chain[key, default: 0] += 1
                
                changesMatrix[previousKey]?[nextKey] = chain
            } else {
                var chain = Matrix<Element>()
                chain[nextKey] = Vector<Element>()
                chain[nextKey]?[key] = 1
                
                changesMatrix[previousKey] = chain
            }
            
            previousKey = nextKey
            nextKey = key
        }

        return changesMatrix
    }
    
    public var secondLast: Element? {
        guard self.count > 2 else { return nil }
        return self[self.count - 2]
    }
}

public extension Collection where Indices.Iterator.Element == Index {
    subscript (exists index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
