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
    
    public static func create(droneSessionManager: DroneSessionManager?) -> CaptureButton {
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
        setImage(DronelinkUI.loadImage(named: "captureIcon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        self.addTarget(self, action: #selector(btnClicked(_:)), for: .touchUpInside)
    }
    
    private func cameraIsCapturing() -> Bool {
        // Check if the camera is capturing
        return droneSessionManager?.session?.cameraState(channel: 0)?.value.isCapturing == true
    }
    
    @objc func btnClicked (_ sender:UIButton) {
        // If camera is capturing then add stop capture command else add start capture command
        try? self.droneSessionManager.session?.add(command: cameraIsCapturing() ? Kernel.StopCaptureCameraCommand() : Kernel.StartCaptureCameraCommand())
    }
    
}
