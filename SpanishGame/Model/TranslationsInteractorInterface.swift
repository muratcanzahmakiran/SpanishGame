//
//  TranslationsInteractorInterface.swift
//  SpanishGame
//
//  Created by Murat Can Zahmakıran on 3.08.2022.
//

import Foundation

typealias Translation = (english: String, spanish: String, isCorrect: Bool)

enum TranslationsInteractorUpdate {
    case initialized
    case initializeFailed(error: String)
}

protocol TranslationsInteractorInterface {
    
    var isTranslationsInitialized: Bool { get }
    
    func initializeTranslations() async throws
    func fetchRandomTranslation(excluding usedWords: [String]) -> Translation
}

// ProjectDefaults
extension TranslationsInteractor: TranslationsInteractorInterface where Storage == WordPairStorage {
    
    convenience init() {
        self.init(storage: WordPairStorage.shared)
    }
}
