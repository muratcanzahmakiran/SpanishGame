//
//  RoundTimer.swift
//  SpanishGame
//
//  Created by Murat Can Zahmakıran on 3.08.2022.
//

import Foundation

final class RoundTimer {
    
    private var timer: Timer?
    
    let interval: TimeInterval
    let fireHandler: () -> Void
    
    init(interval: TimeInterval, fire fireHandler: @escaping () -> Void) {
        self.interval = interval
        self.fireHandler = fireHandler
    }
    
    func start() {
        stop()
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.fireHandler()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    deinit {
        stop()
    }
}
