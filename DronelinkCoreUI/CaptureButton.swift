//
//  CaptureButton.swift
//  DronelinkDJIUI
//
//  Created by Nicolas Torres on 1/12/20.
//  Copyright © 2020 Dronelink. All rights reserved.
//

import Foundation
import UIKit
import DronelinkCore

public class CaptureButton: UIButton {
    
    private var droneSessionManager: DroneSessionManager!
    
    public static func create(droneSessionManager: DroneSessionManager) -> CaptureButton {
        let captureButton = CaptureButton()
        captureButton.droneSessionManager = droneSessionManager
        return captureButton
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configeBtn()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configeBtn()
    }
    
    func configeBtn() {
        self.addTarget(self, action: #selector(btnClicked(_:)), for: .touchUpInside)
    }
    
    @objc func btnClicked (_ sender:UIButton) {
        var command = Kernel.StartCaptureCameraCommand()
        try? self.droneSessionManager.session?.add(command: command)
    }
    
}
