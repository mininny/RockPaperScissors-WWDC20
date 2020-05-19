//#-hidden-code
import UIKit
import PlaygroundSupport
import Core
import RPS

func loadPsychologicalModel() {
    let proxy = PlaygroundPage.current.liveView as? PlaygroundRemoteLiveViewProxy
    let command: PlaygroundValue = .string("Psychological")
    proxy?.send(command)
    PlaygroundPage.current.assessmentStatus = .pass(message: "Maybe, psychological facotrs may affect your RPS playing style more than you realize! Human behavior is interesting... Prooceed to the [Next Page](@next) 🥳")
}
//#-end-hidden-code
/*:
 ## More Factors..?
 
 Now, as you may have already experienced, Rock Paper Scissors is NOT a trivial game that only involves statistics and luck.
 
 When humans play it, RPS is heavily influenced by psychological factors as people pay a lot of attention to what others are playing and they might want to play.
 
 Here is a list of the psychological factors based on several studies:
 * Telling the player what they're going to play and actually play it will likely result in a win.
 * Chance of winning wth scissors in the first round is higher than others.
 * If opponent plays the same movement repeatedly and loses, play a choice that is defeated by the opponent's last choice.
 * If opponent plays the same movement repeatedly and win, play the opponent's last choice.
 * If you win, play what would beat your last movement.
 * If you lose, play what would beat the opponent's last movement.
 * If you draw, continue playing the same thing.
 
 Now, this model includes these key factors into consideration, using psychology to beat you! Try it out how such factors impact the course of a RPS game with the RPS machine on the right.
 */
 //#-code-completion(identifier, show, loadPsychologicalModel())
 // Call loadPsychologicalModel() here
 //#-editable-code
 
 //#-end-editable-code
/*:
 Additionally, in a regular RPS match, players also play a tactic where they tell the opponent what they are going to choose. To experience this, please enable intimidation by toggling `Allow Intimidation`. When toggled, the machine will periodically tell you what move it's going to make. 
 
 ---
 */

public class PsychologyMachine: PsychologicalModel {
//    enum RPS {
//        case rock, paper, scissors
//
//        enum Result {
//            case win, lose, tie
//        }
//    }
//
//    var opponentHistory = [RPS]() // Opponent's previous choices.
//    var selfHistory = [RPS]() // Machine's previous choices.
//    var winHistory = [RPS.Result]() // Machine's previous win/lose histories
    
    override public func process() -> RPS {
        if opponentHistory.isEmpty { // With an empty data, chance of winning with scissors is higher than others
            return .scissors
        }
        
        if let lastMove = opponentHistory.last, lastMove == opponentHistory.secondLast { // If opponent played same movement during te past two rounds,
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
}
