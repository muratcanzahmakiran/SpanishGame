//
//  TranslationsInteractor.swift
//  SpanishGame
//
//  Created by Murat Can Zahmakıran on 1.08.2022.
//

import Foundation

final class TranslationsInteractor {
    
    let storage: WordPairStorageInterface
    
    init(storage: WordPairStorageInterface) {
        self.storage = storage
    }
    
    func initializeTranslations() async throws {
        try await storage.initialize()
    }
    
    func fetchRandomTranslation(excluding usedWords: [String]) -> Translation {
        var wordPairs = storage.wordPairs
        let selectedIndex = wordPairs
            .enumerated()
            .filter { !usedWords.contains($0.element.english) }
            .map { $0.offset }
            .randomElement()!
        let selectedPair = wordPairs.remove(at: selectedIndex)
        
        let isCorrectTranslation = Int.random(in: 0...3) == 0
        let spanish = isCorrectTranslation ? selectedPair.spanish : wordPairs.randomElement()!.spanish
        return (selectedPair.english, spanish, isCorrectTranslation)
    }
}
