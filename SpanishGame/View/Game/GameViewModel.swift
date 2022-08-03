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
        let isSuccessfulAttempt = attempt.isCorrect == currentTranslation?.isCorrect
        if isSuccessfulAttempt {
            correctAttemps += 1
        } else {
            wrongAttemps += 1
        }
        
        updateHandler(.attemptResult(succeeded: isSuccessfulAttempt))
    }
    
    @MainActor
    func fetchNextTranslation() {
        currentTranslation.map { previousWords.append($0.english) }
        
        let translation = interactor.fetchRandomTranslation(excluding: previousWords)
        currentTranslation = translation
        
        updateHandler(.nextTranslation(english: translation.english, spanish: translation.spanish))
    }
}
