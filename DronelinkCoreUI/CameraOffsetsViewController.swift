//
//  CameraOffsetsViewController.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 3/20/20.
//  Copyright © 2020 Dronelink. All rights reserved.
//

import Foundation
import DronelinkCore
import MaterialComponents.MaterialPalettes
import MaterialComponents.MaterialButtons
import MaterialComponents.MaterialProgressView

public class CameraOffsetsViewController: UIViewController {
    
    public static func create(droneSessionManager: DroneSessionManager) -> CameraOffsetsViewController {
        let cameraOffsetsViewController = CameraOffsetsViewController()
        cameraOffsetsViewController.droneSessionManager = droneSessionManager
        return cameraOffsetsViewController
    }
    
    private var droneSessionManager: DroneSessionManager!
    private var session: DroneSession?
    private var exposureCommand: Mission.ExposureCompensationStepCameraCommand?
    
    private let c1Button = MDCFloatingButton()
    private let c2Button = MDCFloatingButton()
    private let cLabel = UILabel()
    
    private let updateInterval: TimeInterval = 0.25
    private var updateTimer: Timer?
    private var offsets: DroneOffsets {
        get { Dronelink.shared.droneOffsets }
        set (newOffsets) { Dronelink.shared.droneOffsets = newOffsets }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        }
        
        view.addShadow()
        view.layer.cornerRadius = DronelinkUI.Constants.cornerRadius
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        configureButton(button: c1Button, image: "baseline_add_white_24pt", action: #selector(onC1(sender:)))
        configureButton(button: c2Button, image: "baseline_remove_white_24pt", action: #selector(onC2(sender:)))
        
        cLabel.textAlignment = .center
        cLabel.font = UIFont.boldSystemFont(ofSize: 14)
        cLabel.textColor = UIColor.white
        cLabel.minimumScaleFactor = 0.5
        cLabel.adjustsFontSizeToFitWidth = true
        view.addSubview(cLabel)
        
        update()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        droneSessionManager.add(delegate: self)
        updateTimer = Timer.scheduledTimer(timeInterval: updateInterval, target: self, selector: #selector(update), userInfo: nil, repeats: true)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        updateTimer?.invalidate()
        updateTimer = nil
        droneSessionManager.remove(delegate: self)
    }
    
    private func configureButton(button: MDCFloatingButton, image: String, color: UIColor? = nil, action: Selector) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setBackgroundColor((color ?? UIColor.darkGray).withAlphaComponent(0.85))
        button.setImage(DronelinkUI.loadImage(named: image), for: .normal)
        button.tintColor = UIColor.white
        button.addTarget(self, action: action, for: .touchUpInside)
        if button.superview == nil {
            view.addSubview(button)
        }
    }
    
    public override func updateViewConstraints() {
        super.updateViewConstraints()
        
        let defaultPadding = 10
        let buttonSize = 42
        
        c1Button.snp.remakeConstraints { make in
            make.height.equalTo(buttonSize)
            make.width.equalTo(buttonSize)
            make.top.equalToSuperview().offset(defaultPadding)
            make.left.equalToSuperview().offset(defaultPadding)
        }
        
        c2Button.snp.remakeConstraints { make in
            make.height.equalTo(buttonSize)
            make.width.equalTo(buttonSize)
            make.top.equalToSuperview().offset(defaultPadding)
            make.right.equalToSuperview().offset(-defaultPadding)
        }
        
        cLabel.snp.remakeConstraints { make in
            make.height.equalTo(buttonSize)
            make.left.equalTo(c1Button.snp.right).offset(defaultPadding)
            make.right.equalTo(c2Button.snp.left).offset(-defaultPadding)
            make.centerY.equalTo(c2Button)
        }
        
        update()
    }
    
    @objc func onC1(sender: Any) {
        guard exposureCommand == nil else {
            return
        }
        
        onEV(steps: -1)
    }
    
    @objc func onC2(sender: Any) {
        guard exposureCommand == nil else {
            return
        }
        
        onEV(steps: 1)
    }
    
    private func onEV(steps: Int) {
        guard let session = session else {
            return
        }
        
        do {
            let exposureCommand = Mission.ExposureCompensationStepCameraCommand(exposureCompensationSteps: steps)
            try? session.add(command: exposureCommand)
            offsets.cameraExposureCompensationSteps += steps
            self.exposureCommand = exposureCommand
            update()
        }
    }
    
    @objc func update() {
        let exposureCompensation = session?.cameraState(channel: 0)?.value.missionExposureCompensation
        c1Button.tintColor = exposureCommand == nil ? UIColor.white : MDCPalette.pink.accent400
        c1Button.isEnabled = exposureCompensation != nil
        c2Button.tintColor = c1Button.tintColor
        c2Button.isEnabled = c1Button.isEnabled
        
        cLabel.text = exposureCompensation == nil ? "" : Dronelink.shared.formatEnum(name: "CameraExposureCompensation", value: exposureCompensation!.rawValue)
    }
}

extension CameraOffsetsViewController: DroneSessionManagerDelegate {
    public func onOpened(session: DroneSession) {
        self.session = session
        session.add(delegate: self)
    }
    
    public func onClosed(session: DroneSession) {
        self.session = nil
        session.remove(delegate: self)
    }
}

extension CameraOffsetsViewController: DroneSessionDelegate {
    public func onInitialized(session: DroneSession) {}
    
    public func onLocated(session: DroneSession) {}
    
    public func onMotorsChanged(session: DroneSession, value: Bool) {}
    
    public func onCommandExecuted(session: DroneSession, command: MissionCommand) {}
    
    public func onCommandFinished(session: DroneSession, command: MissionCommand, error: Error?) {
        guard let exposureCommand = self.exposureCommand else {
            return
        }
        
        if command.id == exposureCommand.id {
            self.exposureCommand = nil
            DispatchQueue.main.async {
                self.view.setNeedsUpdateConstraints()
            }
        }
    }
    
    public func onCameraFileGenerated(session: DroneSession, file: CameraFile) {}
}
