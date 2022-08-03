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

final class GameViewModel {
    
    let interactor: TranslationsInteractorInterface
    private(set) lazy var timer: RoundTimer = {
        return RoundTimer(interval: 5) { [unowned self] in
            processAttemptResult(isSuccessful: false)
        }
    }()
    
    var updateHandler: ((GameViewModelUpdate) -> Void)!
    
    private var previousWords: [String] = []
    private var currentTranslation: Translation?
    
    private(set) var correctAttemps = 0
    private(set) var wrongAttemps = 0
    
    init(interactor: TranslationsInteractorInterface) {
        self.interactor = interactor
    }
    
    @MainActor
    private func emitUpdate(_ update: GameViewModelUpdate) {
        updateHandler(update)
    }
    
    func startGame() {
        updateHandler(.loading(show: true))
        Task { [weak self] in
            do {
                try await interactor.initializeTranslations()
                await self?.fetchNextTranslation()
                await self?.emitUpdate(.loading(show: false))
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
        
        updateHandler(.attemptResult(succeeded: isSuccessful))
    }
    
    @MainActor
    func fetchNextTranslation() {
        currentTranslation.map { previousWords.append($0.english) }
        
        let translation = interactor.fetchRandomTranslation(excluding: previousWords)
        currentTranslation = translation
        
        timer.start()
        
        updateHandler(.nextTranslation(english: translation.english, spanish: translation.spanish))
    }
}
