//
//  PsychologicalModel.swift
//  RPS
//
//  Created by Minhyuk Kim on 2020/05/10.
//

import Foundation

open class PsychologicalModel: RPSable {
    open var selfHistory: [RPS]
    open var opponentHistory: [RPS]
    open var winHistory: [RPS.Result] = []
    
    public var count: Int { self.opponentHistory.count }
    
    public var nextIntimidation: RPS?
    
    public init() {
        self.selfHistory = []
        self.opponentHistory = []
    }
    
    public func predict() -> RPS? {
        let nextMove = self.process()
        
        if let nextIntimidation = self.nextIntimidation, Double.random(in: 0...1.0) < 0.5 { // If intimidation is on, produce a random movement. With 50% change, choose the random movement, or proceed wth the pre-processed movement.
            self.nextIntimidation = nil
            
            self.selfHistory.append(nextIntimidation)
            return nextIntimidation
        }
        
        self.selfHistory.append(nextMove)
        return nextMove
    }
    
    open func process() -> RPS {
        if opponentHistory.isEmpty { // With an empty data, chance of winning with scissors is higher than others
            return .scissors
        }
        
        if let lastMove = opponentHistory.last, lastMove == opponentHistory.secondLast { // If opponent played same movement durign te past two rounds,
            if winHistory.last == .win {
                return lastMove // Play what the opponent played.
            } else {
                return lastMove.defeatingChoice // Reverse opponent's movements. Losers are more likely to switch to movement that beats other player's last move.
            }
        }

        if winHistory.last == .win { // If the model wins,
            if let lastMove = self.selfHistory.last {
                return lastMove.winningChoice // Return a choice that beats last movement to either tie or win.
            } else { return .randomChoice }
        } else if winHistory.last == .draw { // If draw,
            if let lastMove = self.opponentHistory.last {
                return lastMove // Return what opponent last played.
            } else { return .randomChoice }
        } else {
            if let lastMove = self.opponentHistory.last { // If the model lost
                return lastMove.winningChoice // Winners are likely to stick with the choice when they win. 
            } else { return .randomChoice }
        }
    }
    
    public func append(_ item: RPS) {
        self.opponentHistory.append(item)
        
        self.winHistory.append(self.selfHistory.last?.wins(item) ?? .draw)
    }
}
