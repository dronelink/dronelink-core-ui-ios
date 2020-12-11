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
    
    public let cameraModeButton = UIButton()
    
    public let cameraPhotoImage = DronelinkUI.loadImage(named: "cameraPhotoMode")?.withRenderingMode(.alwaysTemplate)
    public let cameraVideoImage = DronelinkUI.loadImage(named: "cameraVideoMode")?.withRenderingMode(.alwaysTemplate)
    
    private var modeCameraCommand: Kernel.ModeCameraCommand?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        configCameraModeButton()
        view.addSubview(cameraModeButton)
        cameraModeButton.isEnabled = false
        cameraModeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(5)
            make.left.equalToSuperview().offset(5)
            make.right.equalToSuperview().offset(-5)
            make.bottom.equalToSuperview().offset(-5)
        }
    }
    
    private func configCameraModeButton() {
        cameraModeButton.setImage( (session?.cameraState(channel: 0)?.value.mode == .video) ? cameraVideoImage : cameraPhotoImage, for: .normal)
        cameraModeButton.tintColor = .white
        cameraModeButton.addTarget(self, action: #selector(cameraModeButtonClicked(_:)), for: .touchUpInside)
    }
    
    private func cameraIsInPhotoMode() -> Bool {
        return session?.cameraState(channel: 0)?.value.mode == .photo
    }
    
    @objc func cameraModeButtonClicked (_ sender:UIButton) {
        
        cameraModeButton.isEnabled = false
        
        var cmd = Kernel.ModeCameraCommand()
        
        cmd.mode = cameraIsInPhotoMode() ? .video : .photo
        
        self.modeCameraCommand = cmd
        
        try? self.session?.add(command: cmd)
    }
    
    @objc public override func update() {
        super.update()
        
        guard let cameraMode = (session?.cameraState(channel: 0)?.value.mode) else {return}
        
        cameraModeButton.setImage( ( cameraMode == .video) ? cameraVideoImage : cameraPhotoImage, for: .normal)
        
        cameraModeButton.isEnabled = !(session?.cameraState(channel: 0)?.value.isCapturing ?? false)
    }
    
    public override func onClosed(session: DroneSession) {
        super.onClosed(session: session)
        DispatchQueue.main.async {
            self.cameraModeButton.setImage(self.cameraPhotoImage, for: .normal)
            self.cameraModeButton.isEnabled = false
        }
    }
    
    public override func onOpened(session: DroneSession) {
        super.onOpened(session: session)
        DispatchQueue.main.async {
            self.cameraModeButton.isEnabled = true
        }
    }
    
    public override func onCommandFinished(session: DroneSession, command: KernelCommand, error: Error?) {
        
        super.onCommandFinished(session: session, command: command, error: error)
        
        guard let cameraModeCommand = self.modeCameraCommand else {
            return
        }
        
        self.modeCameraCommand = nil
        
        DispatchQueue.main.async {
            self.cameraModeButton.isEnabled = (command.id == cameraModeCommand.id)
        }
      }
}
