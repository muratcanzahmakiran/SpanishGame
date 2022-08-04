//
//  GameViewModel.swift
//  SpanishGame
//
//  Created by Murat Can Zahmakıran on 3.08.2022.
//

import Foundation

// Configuration
private var roundTimeInterval = 5.0
private var maxAttempts = 15
private var maxWrongAttemps = 3
// ---

private extension Attempt {
    var isCorrect: Bool { self == .correct }
}

@MainActor
final class GameViewModel<Interactor: TranslationsInteractorInterface,
                          Timer: RoundTimerInterface> {
    
    let interactor: Interactor
    private(set) lazy var timer: Timer = {
        return Timer(interval: roundTimeInterval) { [unowned self] in
            self.processAttemptResult(isSuccessful: false)
        }
    }()
    
    var updateHandler: ((GameViewModelUpdate) -> Void)?
    
    var roundDuration: TimeInterval { roundTimeInterval }
    
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
        previousWords.removeAll()
        currentTranslation = nil
        
        correctAttemps = 0
        wrongAttemps = 0
        
        if interactor.isTranslationsInitialized {
            completeGameStart()
            return
        }
        
        emitUpdate(.loading(show: true))
        Task {
            do {
                try await interactor.initializeTranslations()
                completeGameStart()
            } catch {
                emitUpdate(.loadFailed(message: "Translations could not be loaded."))
            }
            emitUpdate(.loading(show: false))
        }
    }
    
    private func completeGameStart() {
        emitUpdate(.scoreChanged)
        fetchNextTranslation()
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
        
        emitUpdate(.scoreChanged)
        if correctAttemps + wrongAttemps >= maxAttempts || wrongAttemps >= maxWrongAttemps {
            emitUpdate(.gameOver)
            return
        }
        
        fetchNextTranslation()
    }
    
    private func fetchNextTranslation() {
        currentTranslation.map { previousWords.append($0.english) }
        
        let translation = interactor.fetchRandomTranslation(excluding: previousWords)
        currentTranslation = translation
        
        timer.start()
        
        emitUpdate(.nextTranslation(english: translation.english, spanish: translation.spanish))
    }
}
