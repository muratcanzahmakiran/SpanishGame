//
//  WordPairStorage.swift
//  SpanishGame
//
//  Created by Murat Can Zahmakıran on 2.08.2022.
//

import Foundation

final class WordPairStorage {
    
    enum InitializationError: Error {
        case fileNotFound
        case invalidData
        case invalidJSON
    }
    
    static let shared = WordPairStorage()
    
    private(set) var wordPairs: [WordPair] = []
    
    func initialize() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let url = Bundle.main.url(forResource: "words", withExtension: "json") else {
                    continuation.resume(throwing: InitializationError.fileNotFound)
                    return
                }
                
                guard let data = try? Data(contentsOf: url) else {
                    continuation.resume(throwing: InitializationError.invalidData)
                    return
                }
                
                guard let words = try? JSONDecoder().decode([WordPair].self, from: data) else {
                    continuation.resume(throwing: InitializationError.invalidJSON)
                    return
                }
                
                self.wordPairs = words
                continuation.resume(returning: ())
            }
        }
    }
}
