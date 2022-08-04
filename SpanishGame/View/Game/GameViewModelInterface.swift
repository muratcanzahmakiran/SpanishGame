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
    case scoreChanged
    case gameOver
}

protocol GameViewModelInterface: AnyObject {
    var updateHandler: ((GameViewModelUpdate) -> Void)? { get set }
    
    var roundDuration: TimeInterval { get }
    
    var correctAttemps: Int { get }
    var wrongAttemps: Int { get }
    
    func startGame()
    func validateAttempt(_ attempt: Attempt)
}

// Project Defaults
extension GameViewModel: GameViewModelInterface
where Interactor == TranslationsInteractor<WordPairStorage>,
      Timer == RoundTimer {
    
    convenience init() {
        self.init(interactor: TranslationsInteractor())
    }
}
