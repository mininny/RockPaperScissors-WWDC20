//#-hidden-code
import RPS
import PlaygroundSupport

func enableWeightedCalculation() {
    let proxy = PlaygroundPage.current.liveView as? PlaygroundRemoteLiveViewProxy
    let command: PlaygroundValue = .string("Weighted")
    proxy?.send(command)
    
    PlaygroundPage.current.assessmentStatus = .pass(message: "Now, not only can we remember and use statistics to make better judgements, but we can also adjust to the opponent player! Proceed to continue hacking the RPS game... 👉 [Next Page](@next)")
}
//#-end-hidden-code
/*:
# Weighing Results
 Previously, we used Markov Model to remember the opponent's previous movements, and use those results to choose the most probably answer.
 
 However, this approach may perform bad if the user changes his/her strategies frequently. Because Markov Model uses certain number of list to make judgement, this results in unflexible logic.
 
 So what we can do here is Weighing the results.
 
 After each round, we will reduce the significance of the choice. This allows us to flexibly adjust to changing strategies, hence make better judgements.
 
 For example, when a user plays ✌️, 🖐, ✊, ✊, ✌️, the corresponding signifcance may be 60%, 70%, 80%, 90%, 100%.
 
 Enable Weighted Calculation on Markov Model and see how it performs!
 */
 //#-code-completion(identifier, show, enableWeightedCalculation())
 // Call enableWeightedCalculation() function here.
 //#-editable-code
 
 //#-end-editable-code
/*:
 - Important: You may notice that the model performs poorly initially, but starts to get better as you play more rounds. This is because the model is producing a better weight graph eaech time it plays, thus producing more accurate result.
 
 Here is a code snippet of how Weighted Calculation may work. 
 */

class WeightedMarkovMachine: MarkovModel {
//    open class WeightedRPS {
//        let choice: RPS
//        let rounds: Int // The round of a WeightedRPS is the index of the turn when the user played this specific choice.
//
//        public init(choice: RPS, rounds: Int) {
//            self.choice = choice
//            self.rounds = rounds
//        }
//    }
    
//    open var weightedChain: [RPS: [WeightedRPS]] // This is weighted chain. Each RPS choice is mapped with an array of WeightedRPS.
    
    override open func predictWeightedChain() -> RPS? {
        guard let last = self.opponentHistory.last else { return nil }
        
        let weightedResults = self.weightedChain[last]?.reduce(into: [RPS:Double](), { (result, rps) in // Take the previous history of weighted choices
            result[rps.choice, default: 0.0] += (1-((Double(self.count - rps.rounds))*0.04)) // After Every turn, every previous choice's significance is dropped by 4 percent.
        })
        let result = weightedResults?.max(by: { $0.value < $1.value })?.key ?? .rock // Aggregate all the weight by each choice and pick the largest one.
        return result.winningChoice
    }
    
    override open func predict() -> RPS? {
        return self.predictWeightedChain() // Return Weighted Result
    }
}
