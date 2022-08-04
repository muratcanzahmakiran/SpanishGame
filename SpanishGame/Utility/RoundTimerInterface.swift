//
//  RoundTimerInterface.swift
//  SpanishGame
//
//  Created by Murat Can Zahmakıran on 4.08.2022.
//

import Foundation

protocol RoundTimerInterface {
    
    init(interval: TimeInterval, fire fireHandler: @escaping () -> Void)
    
    func start()
    func stop()
}

// ProjectDefaults
extension RoundTimer: RoundTimerInterface {}
