//
//  WordPair.swift
//  SpanishGame
//
//  Created by Murat Can Zahmakıran on 1.08.2022.
//

import Foundation

struct WordPair: Equatable, Decodable {
    let english: String
    let spanish: String
    
    private enum CodingKeys: String, CodingKey {
        case english = "text_eng"
        case spanish = "text_spa"
    }
}
