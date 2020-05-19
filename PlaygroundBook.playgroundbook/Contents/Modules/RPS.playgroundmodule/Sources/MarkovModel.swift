//
//  MarkovModel.swift
//  RPS
//
//  Created by Minhyuk Kim on 2020/05/18.
//  Copyright © 2020 Minhyuk Kim. All rights reserved.
//

import Foundation

open class WeightedRPS: Hashable {
    static public func == (lhs: WeightedRPS, rhs: WeightedRPS) -> Bool {
        return lhs.choice == rhs.choice && lhs.rounds == rhs.rounds
    }
    
    public let choice: RPS
    public let rounds: Int
    
    public init(choice: RPS, rounds: Int) {
        self.choice = choice
        self.rounds = rounds
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(choice)
        hasher.combine(rounds)
    }
}

open class MarkovModel: RPSable {
    open var singleChain: Matrix<RPS> // This is a single layered chain. E.g. ✊ -> ✌️
    open var doubleChain: DoubleMatrix<RPS> // This is a double layered chain. E.g. 🖐 -> ✌️ -> ✊
    open var opponentHistory: [RPS] // This is the actual history of the opponent's movements.
    open var weightedChain: [RPS: [WeightedRPS]] // This is weighted chain.
    
    public var count: Int { self.opponentHistory.count }
    public var limit = 30 {
        didSet {
            if self.limit > self.count { // If the model has more data than the limit
                while self.opponentHistory.count > self.limit { // it removes oldest history until it satisfies the constraint.
                    self.opponentHistory.removeFirst()
                }
            }
        }
    }
    
    public var useWeightedChain = false
    
    public init() {
        self.opponentHistory = []
        self.singleChain = [RPS]().makeTransitionsMatrix()
        self.doubleChain = [RPS]().makeTransitionsDoubleMatrix()
        self.weightedChain = [:]
    }
    
    open func predictWeightedChain() -> RPS? {
        guard let last = self.opponentHistory.last else { return nil }
        
        let weightedResults = self.weightedChain[last]?.reduce(into: [RPS:Double](), { (result, rps) in
            result[rps.choice, default: 0.0] += (1-((Double(self.count - rps.rounds))*0.04))
        })
        let result = weightedResults?.max(by: { $0.value < $1.value })?.key ?? .rock
        return result.winningChoice
    }
    
    open func predict() -> RPS? {
        if useWeightedChain {
            return self.predictWeightedChain()
        }
        
        guard let singlePrediction = predictSingle(), let singleChoice = singlePrediction.max(by: { $0.value < $1.value }) else { return .randomChoice } // No data, retunr random movement
        guard let doublePrediction = predictDouble(), let doubleChoice = doublePrediction.max(by: { $0.value < $1.value }) else { return singleChoice.key } // No double chained result, returning data from the single layered chain.
        
        let singleChoiceProbability = Double(singleChoice.value)/Double(singlePrediction.values.reduce(1,+)) // Getting the probability for the single chain
        let doubleChoiceProbability = Double(doubleChoice.value)/Double(doublePrediction.values.reduce(1,+)) // Getting the probability for the double chain.
        
        return (singleChoiceProbability > doubleChoiceProbability) ? singleChoice.key.winningChoice : doubleChoice.key.winningChoice // Return the result with more probability.
    }
    
    open func predictSingle() -> [RPS: Int]? { // Returns the dictionary of the history of opponent's play following the given movement with a single chain model.
        guard let value = self.opponentHistory.last else { return nil }
        return singleChain.probabilities(given: value)
    }
    
    open func predictDouble() -> [RPS: Int]? { // Returns the dictionary of the history of opponent's play following the given movement with a double chain model .
        guard let first = self.opponentHistory.secondLast,
            let second = self.opponentHistory.last else { return nil }
        return doubleChain.probabilities(given: (first, second))
    }
    
    public func append(_ item: RPS) {
        if self.opponentHistory.count > self.limit { self.opponentHistory.removeFirst() }
        
        guard let old = self.opponentHistory.last else {
            self.opponentHistory.append(item)
            return
        }
        
        var newChain = self.singleChain[old] ?? Vector<RPS>()
        newChain[item, default: 0] += 1
        self.singleChain[old] = newChain
        
        let weightedRPS = WeightedRPS(choice: item, rounds: self.count)
        self.weightedChain[old, default: []].append(weightedRPS)
        
        if let secondLast = self.opponentHistory.secondLast {
            var newChain =  self.doubleChain[secondLast]?[old] ?? Vector<RPS>()
            newChain[item, default: 0] += 1
            if self.doubleChain[secondLast] != nil {
                self.doubleChain[secondLast]![old] = newChain
            } else {
                self.doubleChain[secondLast] = Matrix<RPS>()
                self.doubleChain[secondLast]![old] = newChain
            }
        }
        
        self.opponentHistory.append(item)
    }
}
