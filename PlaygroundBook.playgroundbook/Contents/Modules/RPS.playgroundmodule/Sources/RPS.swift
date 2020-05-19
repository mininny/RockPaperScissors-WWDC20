//
//  RPS.swift
//  RPS
//
//  Created by Minhyuk Kim on 2020/05/09.
//

import Foundation

public enum RPS {
    case rock, paper, scissors
    
    public enum Double: CaseIterable {
        case RR, RS, RP
        case PR, PS, PP
        case SR, SS, SP
        
        static public func doubleRPS(_ rps1: RPS, _ rps2: RPS) -> RPS.Double {
            switch rps1 {
            case .rock:
                switch rps2 {
                case .rock: return .RR
                case .paper: return .RP
                case .scissors: return .RS
                }
            case .paper:
                switch rps2 {
                case .rock: return .PR
                case .paper: return .PP
                case .scissors: return .PS
                }
            case .scissors:
                switch rps2 {
                case .rock: return .SR
                case .paper: return .SP
                case .scissors: return .SS
                }
            }
        }
    }
    
    public var winningChoice: RPS {
        switch self {
        case .rock:
            return .paper
        case .paper:
            return .scissors
        case .scissors:
            return .rock
        }
    }
    
    public var defeatingChoice: RPS {
        switch self {
        case .rock:
            return .scissors
        case .paper:
            return .rock
        case .scissors:
            return .paper
        }
    }
    
    static public var randomChoice: RPS {
        let randomInt = Int.random(in: 0...2)
        switch randomInt {
        case 0:
            return .rock
        case 1:
            return .paper
        case 2:
            return .scissors
        default:
            return .rock
        }
    }
    
    public var asEmoji: String {
        switch self {
            case .paper: return "✋"
            case .rock: return "✊"
            case .scissors:return "✌️"
        }
    }
    
    public var asInt: Int {
        switch self {
        case .rock: return 0
        case .paper: return 1
        case .scissors: return 2
        }
    }
    
    public func wins(_ choice: RPS) -> Result {
        if choice.winningChoice == self {
            return .win
        } else if choice == self {
            return .draw
        }
        return .lose
    }
    
    func winValue(for choice: RPS) -> Int {
        if choice.winningChoice == self {
            return 100
        } else if choice == self {
            return 50
        }
        return 0
    }
    
    public enum Result {
        case win
        case draw
        case lose
    }
}
