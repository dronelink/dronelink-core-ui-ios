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
    
    public var cameraModeButton: UIButton?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        cameraModeButton = UIButton()
        configCameraModeButton()
        view.addSubview(cameraModeButton!)
        cameraModeButton?.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func configCameraModeButton() {
        cameraModeButton?.setImage( (session?.cameraState(channel: 0)?.value.mode == .photo) ? DronelinkUI.loadImage(named: "cameraPhotoMode")?.withRenderingMode(.alwaysTemplate) : DronelinkUI.loadImage(named: "cameraVideoMode")?.withRenderingMode(.alwaysTemplate), for: .normal)
        cameraModeButton?.tintColor = .white
        cameraModeButton?.addTarget(self, action: #selector(cameraModeButtonClicked(_:)), for: .touchUpInside)
    }
    
    private func cameraIsInPhotoMode() -> Bool {
        return session?.cameraState(channel: 0)?.value.mode == .photo
    }
    
    @objc func cameraModeButtonClicked (_ sender:UIButton) {
        
        var cmd = Kernel.ModeCameraCommand()
        
        cmd.mode = cameraIsInPhotoMode() ? .video : .photo
        
        try? self.session?.add(command: cmd)
    }
    
    @objc public override func update() {
        super.update()
        
        guard let cameraMode = (session?.cameraState(channel: 0)?.value.mode) else {return}
        
        cameraModeButton?.setImage( ( cameraMode == .photo) ? DronelinkUI.loadImage(named: "cameraPhotoMode")?.withRenderingMode(.alwaysTemplate) : DronelinkUI.loadImage(named: "cameraVideoMode")?.withRenderingMode(.alwaysTemplate), for: .normal)
    }
}
