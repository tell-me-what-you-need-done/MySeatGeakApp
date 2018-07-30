//
//  TheSearchTimer.swift
//  MySeatGeekApp
//
//  Created by Scott Bennett on 7/27/18.
//

import UIKit

// This class will manage two timers for auto search in the background.
// The firing will happen after a short interval if there are no additonal activations.
// If there are a continious stream (user types fast) of activations, firing
//only happens on every long interval.

class TheSearchTimer {
    
    let shortInterval: TimeInterval
    let longInterval: TimeInterval
    let callback: () -> Void
    
    var shortTimer: Timer?
    var longTimer: Timer?
    
    enum Const {
        // Auto-search at least this frequently while typing
        static let longAutosearchDelay: TimeInterval = 2.0
        // Trigger automatically after a pause of this length
        static let shortAutosearchDelay: TimeInterval = 0.75
    }
    
    init(short: TimeInterval = Const.shortAutosearchDelay,
         long: TimeInterval = Const.longAutosearchDelay,
         callback: @escaping () -> Void)
    {
        shortInterval = short
        longInterval = long
        self.callback = callback
    }
    
    func activate() {
        shortTimer?.invalidate()
        shortTimer = Timer.scheduledTimer(withTimeInterval: shortInterval, repeats: false)
        { [weak self] _ in self?.fire() }
        if longTimer == nil {
            longTimer = Timer.scheduledTimer(withTimeInterval: longInterval, repeats: false)
            { [weak self] _ in self?.fire() }
        }
    }
    
    func cancel() {
        shortTimer?.invalidate()
        longTimer?.invalidate()
        shortTimer = nil; longTimer = nil
    }
    
    private func fire() {
        cancel()
        callback()
    }
    
}
