//
//  GameViewModelInterface.swift
//  SpanishGame
//
//  Created by Murat Can Zahmakıran on 3.08.2022.
//

import Foundation

enum Attempt {
    case correct
    case wrong
}

enum GameViewModelUpdate {
    case loading(show: Bool)
    case loadFailed(message: String)
    case nextTranslation(english: String, spanish: String)
    case attemptResult(succeeded: Bool)
}

protocol GameViewModelInterface: AnyObject {
    var updateHandler: ((GameViewModelUpdate) -> Void)! { get set }
    
    var correctAttemps: Int { get }
    var wrongAttemps: Int { get }
    
    func startGame()
    func validateAttempt(_ attempt: Attempt)
    func fetchNextTranslation()
}

// Project Defaults
extension GameViewModel: GameViewModelInterface {
    
    convenience init() {
        self.init(interactor: TranslationsInteractor())
    }
}
