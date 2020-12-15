//
//  CameraModeWidget.swift
//  DronelinkCoreUI
//
//  Created by Nicolas Torres on 8/12/20.
//  Copyright © 2020 Dronelink. All rights reserved.
//

import Foundation
import UIKit
import DronelinkCore
import MaterialComponents.MaterialPalettes
import MaterialComponents.MaterialButtons
import MaterialComponents.MaterialButtons_Theming
import MarqueeLabel

public class CameraModeWidget: UpdatableWidget {
    public override var updateInterval: TimeInterval { 0.5 }
    
    public var channel: UInt = 0
    private var cameraState: CameraStateAdapter? { session?.cameraState(channel: channel)?.value }
    
    public let cameraModeButton = UIButton()
    public let cameraPhotoImage = DronelinkUI.loadImage(named: "cameraPhotoMode")?.withRenderingMode(.alwaysTemplate)
    public let cameraVideoImage = DronelinkUI.loadImage(named: "cameraVideoMode")?.withRenderingMode(.alwaysTemplate)
    
    private var pendingCommand: KernelCommand?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        cameraModeButton.setImage(cameraState?.mode == .video ? cameraVideoImage : cameraPhotoImage, for: .normal)
        cameraModeButton.tintColor = .white
        cameraModeButton.addTarget(self, action: #selector(onTapped(_:)), for: .touchUpInside)
        view.addSubview(cameraModeButton)
        cameraModeButton.isEnabled = false
        cameraModeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(5)
            make.left.equalToSuperview().offset(5)
            make.right.equalToSuperview().offset(-5)
            make.bottom.equalToSuperview().offset(-5)
        }
    }
    
    @objc func onTapped(_ sender: UIButton) {
        cameraModeButton.isEnabled = false
        var command = Kernel.ModeCameraCommand()
        command.mode = cameraState?.mode == .photo ? .video : .photo
        do {
            try? session?.add(command: command)
            pendingCommand = command
        }
    }
    
    @objc public override func update() {
        super.update()
        cameraModeButton.setImage(cameraState?.mode == .video ? cameraVideoImage : cameraPhotoImage, for: .normal)
        cameraModeButton.isEnabled = pendingCommand == nil && session != nil && !(session?.cameraState(channel: 0)?.value.isCapturing ?? false)
    }
    
    public override func onClosed(session: DroneSession) {
        pendingCommand = nil
    }
    
    public override func onCommandFinished(session: DroneSession, command: KernelCommand, error: Error?) {
        super.onCommandFinished(session: session, command: command, error: error)
        if pendingCommand?.id == command.id {
            pendingCommand = nil
        }
    }
}
