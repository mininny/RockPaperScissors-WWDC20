//
//  RPSable.swift
//  RPS
//
//  Created by Minhyuk Kim on 2020/05/10.
//

import Foundation

public protocol RPSable {
    func predict() -> RPS?
    func append(_ item: RPS)
    
    var opponentHistory: [RPS] { get set }
    var count: Int { get }
}
