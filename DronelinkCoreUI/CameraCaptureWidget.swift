//
//  CameraCaptureWidget.swift
//  DronelinkCoreUI
//
//  Created by Nicolas Torres on 3/12/20.
//  Copyright © 2020 Dronelink. All rights reserved.
//
import UIKit
import DronelinkCore
import MaterialComponents.MaterialPalettes
import MaterialComponents.MaterialButtons
import MaterialComponents.MaterialButtons_Theming
import MarqueeLabel

public class CameraCaptureWidget: UpdatableWidget {
    
    public var captureButton: UIButton?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        captureButton = UIButton()
        configCaptureButton()
        view.addSubview(captureButton!)
        captureButton?.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        captureButton!.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func configCaptureButton() {
        captureButton?.setImage(DronelinkUI.loadImage(named: "captureIcon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        captureButton?.addTarget(self, action: #selector(captureButtonClicked(_:)), for: .touchUpInside)
    }
    
    private func cameraIsCapturing() -> Bool {
        // Check if the camera is capturing
        return session?.cameraState(channel: 0)?.value.isCapturing == true
    }
    
    @objc func captureButtonClicked (_ sender:UIButton) {
        // If camera is capturing then add stop capture command else add start capture command
        try? self.session?.add(command: cameraIsCapturing() ? Kernel.StopCaptureCameraCommand() : Kernel.StartCaptureCameraCommand())
    }
    
    @objc override func update() {
        super.update()
    }
}
