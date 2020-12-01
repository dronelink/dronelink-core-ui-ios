//
//  Widget.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 12/1/20.
//  Copyright © 2020 Dronelink. All rights reserved.
//
import UIKit
import Foundation
import DronelinkCore

public class Widget: UIViewController {
    public var droneSessionManager: DroneSessionManager?
    
    internal var primaryDroneSessionManager: DroneSessionManager? {
        if let droneSessionManager = droneSessionManager {
            return droneSessionManager
        }
        
        for droneSessionManager in Dronelink.shared.droneSessionManagers {
            if droneSessionManager.session != nil {
                return droneSessionManager
            }
        }
        
        return Dronelink.shared.droneSessionManagers.first
    }
}

public class UpdatableWidget: Widget {
    internal var updateInterval: TimeInterval { 1.0 }
    internal var updateTimer: Timer?
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        update()
        updateTimer = Timer.scheduledTimer(timeInterval: updateInterval, target: self, selector: #selector(update), userInfo: nil, repeats: true)
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    public override func updateViewConstraints() {
        super.updateViewConstraints()
        update()
    }
    
    @objc func update() {}
}
