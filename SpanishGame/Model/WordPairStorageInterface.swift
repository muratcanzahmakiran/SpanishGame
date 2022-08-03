//
//  WordPairStorageInterface.swift
//  SpanishGame
//
//  Created by Murat Can Zahmakıran on 3.08.2022.
//

import Foundation

protocol WordPairStorageInterface {
    
    var wordPairs: [WordPair] { get }
    
    func initialize() async throws
}

extension WordPairStorage: WordPairStorageInterface {}
