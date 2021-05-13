//
//  CameraOffsetsWidget.swift
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

public class CameraOffsetsWidget: UpdatableWidget {
    public override var updateInterval: TimeInterval { 0.25 }
    
    private let c1Image = DronelinkUI.loadImage(named: "baseline_remove_white_24pt")
    private let c2Image = DronelinkUI.loadImage(named: "baseline_add_white_24pt")
    
    private var exposureCommand: Kernel.ExposureCompensationStepCameraCommand?
    
    private let c1Button = MDCFloatingButton()
    private let c2Button = MDCFloatingButton()
    private let cLabel = UILabel()
    
    private let listenRCButtonsInterval: TimeInterval = 0.1
    private var listenRCButtonsTimer: Timer?
    private var c1PressedPrevious = false
    private var c2PressedPrevious = false
    private var evStepsPending: Int?
    private var evStepsTimer: Timer?
    
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
        view.backgroundColor = DronelinkUI.Constants.overlayColor
        
        configureButton(button: c1Button, action: #selector(onC1(sender:)))
        configureButton(button: c2Button, action: #selector(onC2(sender:)))
        
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
        listenRCButtonsTimer = Timer.scheduledTimer(timeInterval: listenRCButtonsInterval, target: self, selector: #selector(listenRCButtons), userInfo: nil, repeats: true)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        listenRCButtonsTimer?.invalidate()
        listenRCButtonsTimer = nil
    }
    
    private func configureButton(button: MDCFloatingButton, color: UIColor? = nil, action: Selector) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setBackgroundColor((color ?? UIColor.darkGray).withAlphaComponent(0.85))
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
        
        c1Button.snp.remakeConstraints { [weak self] make in
            make.height.equalTo(buttonSize)
            make.width.equalTo(buttonSize)
            make.top.equalToSuperview().offset(defaultPadding)
            make.left.equalToSuperview().offset(defaultPadding)
        }
        
        c2Button.snp.remakeConstraints { [weak self] make in
            make.height.equalTo(buttonSize)
            make.width.equalTo(buttonSize)
            make.top.equalToSuperview().offset(defaultPadding)
            make.right.equalToSuperview().offset(-defaultPadding)
        }
        
        cLabel.snp.remakeConstraints { [weak self] make in
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
        evStepsTimer?.invalidate()
        
        if let evStepsPending = self.evStepsPending {
            self.evStepsPending = evStepsPending + steps
        }
        else {
            evStepsPending = steps
        }
        
        evStepsTimer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false) { [weak self] timer in
            guard let session = self?.session, let steps = self?.evStepsPending else {
                return
            }
            
            self?.evStepsPending = nil
            if steps == 0 {
                return
            }
            
            do {
                let exposureCommand = Kernel.ExposureCompensationStepCameraCommand(exposureCompensationSteps: steps)
                try? session.add(command: exposureCommand)
                self?.offsets.cameraExposureCompensationSteps += steps
                self?.exposureCommand = exposureCommand
                self?.update()
            }
        }
    }
    
    @objc open override func update() {
        super.update()
        
        let exposureCompensation = session?.cameraState(channel: 0)?.value.exposureCompensation
        c1Button.tintColor = exposureCommand == nil ? UIColor.white : DronelinkUI.Constants.secondaryColor
        c1Button.isEnabled = exposureCompensation != nil
        c2Button.tintColor = c1Button.tintColor
        c2Button.isEnabled = c1Button.isEnabled
        
        if let evStepsPending = evStepsPending, evStepsPending != 0 {
            if evStepsPending > 0 {
                c1Button.setTitle(nil, for: .normal)
                c1Button.setImage(c1Image, for: .normal)
                c2Button.setTitle("+\(evStepsPending)", for: .normal)
                c2Button.setImage(nil, for: .normal)
            }
            else {
                c1Button.setTitle("\(evStepsPending)", for: .normal)
                c1Button.setImage(nil, for: .normal)
                c2Button.setTitle(nil, for: .normal)
                c2Button.setImage(c2Image, for: .normal)
            }
        }
        else {
            c1Button.setImage(c1Image, for: .normal)
            c1Button.setTitle(nil, for: .normal)
            c2Button.setImage(c2Image, for: .normal)
            c2Button.setTitle(nil, for: .normal)
        }
        
        cLabel.text = exposureCompensation == nil ? "" : Dronelink.shared.formatEnum(name: "CameraExposureCompensation", value: exposureCompensation!.rawValue)
    }
    
    @objc func listenRCButtons() {
        if !(Dronelink.shared.missionExecutor?.engaged ?? false) {
            return
        }
        
        if exposureCommand == nil, let remoteControllerState = session?.remoteControllerState(channel: 0)?.value {
            if c1PressedPrevious, !remoteControllerState.c1Button.pressed {
                onEV(steps: -1)
            }
            
            if c2PressedPrevious, !remoteControllerState.c2Button.pressed {
                onEV(steps: 1)
            }
        }
        
        let remoteControllerState = session?.remoteControllerState(channel: 0)?.value
        c1PressedPrevious = remoteControllerState?.c1Button.pressed ?? false
        c2PressedPrevious = remoteControllerState?.c2Button.pressed ?? false
    }

    open override func onCommandFinished(session: DroneSession, command: KernelCommand, error: Error?) {
        super.onCommandFinished(session: session, command: command, error: error)
        
        guard let exposureCommand = self.exposureCommand else {
            return
        }
        
        if command.id == exposureCommand.id {
            self.exposureCommand = nil
            DispatchQueue.main.async { [weak self] in
                self?.view.setNeedsUpdateConstraints()
            }
        }
    }
}
