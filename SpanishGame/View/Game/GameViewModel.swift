//
//  GameViewModel.swift
//  SpanishGame
//
//  Created by Murat Can Zahmakıran on 3.08.2022.
//

import Foundation

private extension Attempt {
    var isCorrect: Bool { self == .correct }
}

@MainActor
final class GameViewModel<Interactor: TranslationsInteractorInterface,
                          Timer: RoundTimerInterface> {
    
    let interactor: Interactor
    private(set) lazy var timer: Timer = {
        return Timer(interval: 5) { [unowned self] in
            self.processAttemptResult(isSuccessful: false)
        }
    }()
    
    var updateHandler: ((GameViewModelUpdate) -> Void)?
    
    private var previousWords: [String] = []
    private var currentTranslation: Translation?
    
    private(set) var correctAttemps = 0
    private(set) var wrongAttemps = 0
    
    init(interactor: Interactor) {
        self.interactor = interactor
    }
    
    private func emitUpdate(_ update: GameViewModelUpdate) {
        updateHandler?(update)
    }
    
    func startGame() {
        emitUpdate(.loading(show: true))
        Task { [weak self] in
            do {
                try await interactor.initializeTranslations()
                self?.fetchNextTranslation()
                self?.emitUpdate(.loading(show: false))
            }
            
        }
    }
    
    func validateAttempt(_ attempt: Attempt) {
        processAttemptResult(isSuccessful: attempt.isCorrect == currentTranslation?.isCorrect)
    }
    
    private func processAttemptResult(isSuccessful: Bool) {
        if isSuccessful {
            correctAttemps += 1
        } else {
            wrongAttemps += 1
        }
        
        emitUpdate(.attemptResult(succeeded: isSuccessful))
    }
    
    func fetchNextTranslation() {
        currentTranslation.map { previousWords.append($0.english) }
        
        let translation = interactor.fetchRandomTranslation(excluding: previousWords)
        currentTranslation = translation
        
        timer.start()
        
        emitUpdate(.nextTranslation(english: translation.english, spanish: translation.spanish))
    }
}
