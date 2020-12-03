//
//  CameraModeControl.swift
//  DronelinkCoreUI
//
//  Created by Nicolas Torres on 3/12/20.
//  Copyright © 2020 Dronelink. All rights reserved.
//

import Foundation
import UIKit
import DronelinkCore

public class CameraModeControl: UISegmentedControl {
    
    private var droneSessionManager: DroneSessionManager!
    
    public static func create(droneSessionManager: DroneSessionManager) -> CameraModeControl {
        let cameraModeControl = CameraModeControl(items: ["camera", "video"])
        cameraModeControl.droneSessionManager = droneSessionManager
        return cameraModeControl
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
        self.setImage(DronelinkUI.loadImage(named: "cameraIcon")?.withRenderingMode(.alwaysOriginal), forSegmentAt: 0)
        self.setImage(DronelinkUI.loadImage(named: "videoIcon")?.withRenderingMode(.alwaysOriginal), forSegmentAt: 1)
        
        self.addTarget(self, action: #selector(segmentedControlValueChanged(segment:)), for: .valueChanged)
    }
    
    @objc func segmentedControlValueChanged(segment: UISegmentedControl) {
        var command = Kernel.ModeCameraCommand()
        command.mode = segment.selectedSegmentIndex == 0 ? .photo : .video
        try? self.droneSessionManager.session?.add(command: command)
    }
}
