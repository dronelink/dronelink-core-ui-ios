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
    
    public var captureButton: CaptureButton?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        guard let droneSessionManager = primaryDroneSessionManager else {return}
        
        captureButton = CaptureButton.create(droneSessionManager: droneSessionManager)
        
        view.addSubview(captureButton!)
        captureButton!.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    @objc override func update() {
        super.update()
    }
}
