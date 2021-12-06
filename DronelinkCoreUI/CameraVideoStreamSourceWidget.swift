//
//  CameraVideoStreamSourceWidget.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 10/25/21.
//  Copyright © 2021 Dronelink. All rights reserved.
//
import UIKit
import DronelinkCore

public class CameraVideoStreamSourceWidget: CameraWidget {
    public let button = UIButton(type: .custom)
    private var pendingCommand: KernelCommand?
    public var sources: [Kernel.CameraVideoStreamSource] = [.zoom, .wide, .thermal]
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        button.addShadow()
        button.tintColor = UIColor.white
        button.setImage(DronelinkUI.loadImage(named: "camera-switch-outline"), for: .normal)
        button.addTarget(self, action: #selector(onTapped(_:)), for: .touchUpInside)
        view.addSubview(button)
        button.snp.makeConstraints { [weak self] make in
            make.edges.equalToSuperview()
        }
    }
    
    @objc func onTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "CameraVideoStreamSourceWidget.title".localized, message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.sourceView = sender as? UIView
        
        let channel = channelResolved
        sources.forEach { source in
            alert.addAction(UIAlertAction(title: Dronelink.shared.formatEnum(name: "CameraVideoStreamSource", value: source.rawValue, defaultValue: "na".localized), style: .default, handler: { [weak self] _ in
                let command = Kernel.VideoStreamSourceCameraCommand(channel: channel, videoStreamSource: source)
                self?.pendingCommand = command
                try? self?.session?.add(command: command)
            }))
        }

        alert.addAction(UIAlertAction(title: "dismiss".localized, style: .cancel, handler: { _ in

        }))

        present(alert, animated: true)
    }
    
    public override func update() {
        super.update()
        button.isEnabled = pendingCommand == nil
    }
    
    public override func onClosed(session: DroneSession) {
        super.onClosed(session: session)
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
