//
//  UnitSystemControl.swift
//  DronelinkCoreUI
//
//  Created by Nicolas Torres on 3/12/20.
//  Copyright © 2020 Dronelink. All rights reserved.
//

import Foundation
import UIKit
import DronelinkCore

public class UnitSystemControl: UISegmentedControl {
    
    private var droneSessionManager: DroneSessionManager!
    
    public static func create(droneSessionManager: DroneSessionManager) -> UnitSystemControl {
        let unitSystemControl = UnitSystemControl(items: ["metric", "imperial"])
        unitSystemControl.droneSessionManager = droneSessionManager
        return unitSystemControl
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configeControl()
    }
    
    required init(items: [String]) {
        super.init(items: items)
        configeControl()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configeControl()
    }
    
    func configeControl() {
        self.addTarget(self, action: #selector(segmentedControlValueChanged(segment:)), for: .valueChanged)
    }
    
    @objc func segmentedControlValueChanged(segment: UISegmentedControl) {
        
        Dronelink.shared.unitSystem = segment.selectedSegmentIndex == 0 ? .metric : .imperial
        
        // TODO: We need to implement some changes in the Kernel in order to change the Unit System
//        var command = Kernel.UnitSystemCommand()
//        command.unit = segment.selectedSegmentIndex == 0 ? .metric : .imperial
//        try? self.droneSessionManager.session?.add(command: command)
    }
}
