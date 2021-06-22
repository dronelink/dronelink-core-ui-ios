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

public class CameraModeWidget: UpdatableWidget {
    public var channel: UInt = 0
    private var cameraState: CameraStateAdapter? { session?.cameraState(channel: channel)?.value }
    
    public let button = UIButton()
    
    public var photoImage = DronelinkUI.loadImage(named: "cameraPhotoMode")?.withRenderingMode(.alwaysTemplate)
    public var videoImage = DronelinkUI.loadImage(named: "cameraVideoMode")?.withRenderingMode(.alwaysTemplate)
    
    private var pendingCommand: Kernel.ModeCameraCommand?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        button.addShadow()
        button.setImage(cameraState?.mode == .video ? videoImage : photoImage, for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(onTapped(_:)), for: .touchUpInside)
        view.addSubview(button)
        button.isEnabled = false
        button.snp.makeConstraints { [weak self] make in
            make.top.equalToSuperview().offset(5)
            make.left.equalToSuperview().offset(5)
            make.right.equalToSuperview().offset(-5)
            make.bottom.equalToSuperview().offset(-5)
        }
    }
    
    @objc func onTapped(_ sender: UIButton) {
        button.isEnabled = false
        let command = Kernel.ModeCameraCommand(mode: cameraState?.mode == .photo ? .video : .photo)
        do {
            try? session?.add(command: command)
            pendingCommand = command
        }
    }
    
    @objc public override func update() {
        super.update()
        if let pendingCommand = pendingCommand {
            button.setImage(pendingCommand.mode == .video ? videoImage : photoImage, for: .normal)
        }
        else {
            button.setImage(cameraState?.mode == .video ? videoImage : photoImage, for: .normal)
        }
        button.isEnabled = session != nil && pendingCommand == nil
    }
    
    public override func onClosed(session: DroneSession) {
        pendingCommand = nil
    }
    
    public override func onCommandFinished(session: DroneSession, command: KernelCommand, error: Error?) {
        super.onCommandFinished(session: session, command: command, error: error)
        if pendingCommand?.id == command.id {
            pendingCommand = nil
            if let error = error {
                DronelinkUI.shared.showSnackbar(text: error as? String ?? error.localizedDescription)
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.update()
            }
        }
    }
}
