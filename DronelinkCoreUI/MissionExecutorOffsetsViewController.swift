//
//  MissionExecutorOffsetsViewController.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 2/6/20.
//  Copyright © 2020 Dronelink. All rights reserved.
//

import Foundation
import DronelinkCore
import MaterialComponents.MaterialPalettes
import MaterialComponents.MaterialButtons
import MaterialComponents.MaterialProgressView

public class MissionExecutorOffsetsViewController: UIViewController {
    public static func create(droneSessionManager: DroneSessionManager) -> MissionExecutorOffsetsViewController {
        let missionExecutorOffsetsViewController = MissionExecutorOffsetsViewController()
        missionExecutorOffsetsViewController.droneSessionManager = droneSessionManager
        return missionExecutorOffsetsViewController
    }
    
    private var droneSessionManager: DroneSessionManager!
    private var session: DroneSession?
    
    private let detailsLabel = UILabel()
    private let clearButton = UIButton(type: .custom)
    private let leftButton = MDCFloatingButton()
    private let rightButton = MDCFloatingButton()
    private let upButton = MDCFloatingButton()
    private let downButton = MDCFloatingButton()
    private let stickTypeSegmentedControl = UISegmentedControl(items: [
        "MissionExecutorOffsetsViewController.altitudeYaw".localized,
        "MissionExecutorOffsetsViewController.position".localized
    ])
    private let evNegButton = MDCFloatingButton()
    private let evPosButton = MDCFloatingButton()
    private let evLabel = UILabel()
    private let updateInterval: TimeInterval = 1.0
    private var updateTimer: Timer?
    private var exposureCommand: Mission.ExposureCompensationCameraCommand?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        }
        
        view.addShadow()
        view.layer.cornerRadius = DronelinkUI.Constants.cornerRadius
        view.backgroundColor = DronelinkUI.Constants.overlayColor
        
        detailsLabel.textAlignment = .center
        detailsLabel.font = UIFont.boldSystemFont(ofSize: 14)
        detailsLabel.textColor = UIColor.white
        view.addSubview(detailsLabel)
        
        clearButton.tintColor = UIColor.white.withAlphaComponent(0.85)
        clearButton.setImage(DronelinkUI.loadImage(named: "baseline_cancel_white_36pt"), for: .normal)
        clearButton.addTarget(self, action: #selector(onClear), for: .touchUpInside)
        view.addSubview(clearButton)
        
        stickTypeSegmentedControl.selectedSegmentIndex = 0
        stickTypeSegmentedControl.addTarget(self, action:  #selector(onStickTypeChanged(sender:)), for: .valueChanged)
        view.addSubview(stickTypeSegmentedControl)
        
        configureButton(button: leftButton, image: "baseline_arrow_left_white_36pt", action: #selector(onLeft(sender:)))
        configureButton(button: rightButton, image: "baseline_arrow_right_white_36pt", action: #selector(onRight(sender:)))
        configureButton(button: upButton, image: "baseline_arrow_drop_up_white_36pt", action: #selector(onUp(sender:)))
        configureButton(button: downButton, image: "baseline_arrow_drop_down_white_36pt", action: #selector(onDown(sender:)))
        configureButton(button: evNegButton, image: "baseline_remove_white_36pt", action: #selector(onEVNeg(sender:)))
        configureButton(button: evPosButton, image: "baseline_add_white_36pt", action: #selector(onEVPos(sender:)))
        
        evLabel.textAlignment = .center
        evLabel.font = UIFont.boldSystemFont(ofSize: 14)
        evLabel.textColor = detailsLabel.textColor
        view.addSubview(evLabel)
        
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
    
    private func configureButton(button: MDCFloatingButton, image: String, action: Selector) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setBackgroundColor(UIColor.darkGray.withAlphaComponent(0.85))
        button.setImage(DronelinkUI.loadImage(named: image), for: .normal)
        button.tintColor = UIColor.white
        button.addTarget(self, action: action, for: .touchUpInside)
        view.addSubview(button)
    }
    
    public override func updateViewConstraints() {
        super.updateViewConstraints()
        
        let defaultPadding = 10
        let buttonSize = 36
        
        stickTypeSegmentedControl.snp.remakeConstraints { make in
            make.height.equalTo(25)
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
            make.top.equalToSuperview().offset(8)
        }
        
        clearButton.snp.remakeConstraints { make in
            make.height.equalTo(stickTypeSegmentedControl)
            make.width.equalTo(clearButton.snp.height)
            make.right.equalTo(stickTypeSegmentedControl)
            make.top.equalTo(stickTypeSegmentedControl.snp.bottom).offset(defaultPadding)
        }
        
        detailsLabel.snp.remakeConstraints { make in
            make.height.equalTo(stickTypeSegmentedControl)
            make.left.equalTo(stickTypeSegmentedControl)
            make.right.equalTo(clearButton.snp.left).offset(defaultPadding)
            make.top.equalTo(stickTypeSegmentedControl.snp.bottom).offset(defaultPadding)
        }
        
        upButton.snp.remakeConstraints { make in
            make.height.equalTo(buttonSize)
            make.width.equalTo(buttonSize)
            make.top.equalTo(detailsLabel.snp.bottom).offset(5)
            make.centerX.equalToSuperview()
        }
        
        downButton.snp.remakeConstraints { make in
            make.height.equalTo(buttonSize)
            make.width.equalTo(buttonSize)
            make.top.equalTo(upButton.snp.bottom).offset(14)
            make.centerX.equalTo(upButton)
        }
        
        leftButton.snp.remakeConstraints { make in
            make.height.equalTo(buttonSize)
            make.width.equalTo(buttonSize)
            make.top.equalTo(upButton).offset(25)
            make.right.equalTo(upButton.snp.left).offset(-defaultPadding)
        }
        
        rightButton.snp.remakeConstraints { make in
            make.height.equalTo(buttonSize)
            make.width.equalTo(buttonSize)
            make.centerY.equalTo(leftButton)
            make.left.equalTo(upButton.snp.right).offset(defaultPadding)
        }

        evNegButton.snp.remakeConstraints { make in
            make.height.equalTo(buttonSize)
            make.width.equalTo(buttonSize)
            make.bottom.equalToSuperview().offset(-defaultPadding)
            make.left.equalToSuperview().offset(defaultPadding)
        }
        
        evPosButton.snp.remakeConstraints { make in
            make.height.equalTo(buttonSize)
            make.width.equalTo(buttonSize)
            make.bottom.equalToSuperview().offset(-defaultPadding)
            make.right.equalToSuperview().offset(-defaultPadding)
        }
        
        evLabel.snp.remakeConstraints { make in
            make.height.equalTo(buttonSize)
            make.left.equalTo(evNegButton.snp.right).offset(defaultPadding)
            make.right.equalTo(evPosButton.snp.left).offset(-defaultPadding)
            make.centerY.equalTo(evPosButton)
        }
        
        update()
    }
        
    @objc func onStickTypeChanged(sender: Any) {
        update()
    }
    
    @objc func onClear(sender: Any) {
        guard let session = session else {
            return
        }
        
        if stickTypeSegmentedControl.selectedSegmentIndex == 0 {
            session.offsets.droneAltitude = 0
            session.offsets.droneYaw = 0
        }
        else {
            session.offsets.droneCoordinate = Mission.Vector2()
        }
        
        update()
    }
    
    @objc func onLeft(sender: Any) {
        guard let session = session else {
            return
        }
        
        if stickTypeSegmentedControl.selectedSegmentIndex == 0 {
            session.offsets.droneYaw += -3.0.convertDegreesToRadians
        }
        else {
            guard let state = session.state?.value else {
                return
            }
            
            session.offsets.droneCoordinate = session.offsets.droneCoordinate.add(
                vector: Mission.Vector2(
                    direction: state.missionOrientation.yaw - (Double.pi / 2),
                    magnitude: 1.0.convertFeetToMeters))
        }
        
        update()
    }
    
    @objc func onRight(sender: Any) {
        guard let session = session else {
            return
        }
        
        if stickTypeSegmentedControl.selectedSegmentIndex == 0 {
            session.offsets.droneYaw += 3.0.convertDegreesToRadians
        }
        else {
            guard let state = session.state?.value else {
                return
            }
            
            session.offsets.droneCoordinate = session.offsets.droneCoordinate.add(
                vector: Mission.Vector2(
                    direction: state.missionOrientation.yaw + (Double.pi / 2),
                    magnitude: 1.0.convertFeetToMeters))
        }
        
        update()
    }
    
    @objc func onUp(sender: Any) {
        guard let session = session else {
            return
        }
        
        if stickTypeSegmentedControl.selectedSegmentIndex == 0 {
            session.offsets.droneAltitude += 1.0.convertFeetToMeters
        }
        else {
            guard let state = session.state?.value else {
                return
            }
            
            session.offsets.droneCoordinate = session.offsets.droneCoordinate.add(
                vector: Mission.Vector2(
                    direction: state.missionOrientation.yaw,
                    magnitude: 1.0.convertFeetToMeters))
        }
        
        update()
    }
    
    @objc func onDown(sender: Any) {
        guard let session = session else {
            return
        }
        
        if stickTypeSegmentedControl.selectedSegmentIndex == 0 {
            session.offsets.droneAltitude += -1.0.convertFeetToMeters
        }
        else {
            guard let state = session.state?.value else {
                return
            }
            
            session.offsets.droneCoordinate = session.offsets.droneCoordinate.add(
                vector: Mission.Vector2(
                    direction: state.missionOrientation.yaw + Double.pi,
                    magnitude: 1.0.convertFeetToMeters))
        }
        
        update()
    }
    
    @objc func onEVNeg(sender: Any) {
        guard exposureCommand == nil, let exposureCompensation = session?.cameraState(channel: 0)?.value.missionExposureCompensation else {
            return
        }
        
        onEV(exposureCompensation: exposureCompensation.previous)
    }
    
    @objc func onEVPos(sender: Any) {
        guard exposureCommand == nil, let exposureCompensation = session?.cameraState(channel: 0)?.value.missionExposureCompensation else {
            return
        }
        
        onEV(exposureCompensation: exposureCompensation.next)
    }
    
    private func onEV(exposureCompensation: Mission.CameraExposureCompensation) {
        do {
            let exposureCommand = Mission.ExposureCompensationCameraCommand(exposureCompensation: exposureCompensation)
            try? session?.add(command: exposureCommand)
            self.exposureCommand = exposureCommand
            update()
        }
    }
    
    @objc func update() {
        let offsets = session?.offsets ?? DroneSessionOffsets()
        
        if stickTypeSegmentedControl.selectedSegmentIndex == 0 {
            var details: [String] = []
            if offsets.droneYaw != 0 {
                details.append(Dronelink.shared.format(formatter: "angle", value: offsets.droneYaw))
            }
            
            if offsets.droneAltitude != 0 {
                details.append(Dronelink.shared.format(formatter: "altitude", value: offsets.droneAltitude))
            }
            
            clearButton.isHidden = details.count == 0
            detailsLabel.text = details.joined(separator: " / ")
        }
        else {
            clearButton.isHidden = offsets.droneCoordinate.magnitude == 0
            detailsLabel.text = clearButton.isHidden ? "" : "\(Dronelink.shared.format(formatter: "angle", value: offsets.droneCoordinate.direction)) → \(Dronelink.shared.format(formatter: "distance", value: offsets.droneCoordinate.magnitude))"
        }
        
        var exposureCompensation = session?.cameraState(channel: 0)?.value.missionExposureCompensation
        evNegButton.tintColor = exposureCommand == nil ? UIColor.white : MDCPalette.pink.accent400
        evNegButton.isEnabled = exposureCompensation != nil
        evPosButton.tintColor = evNegButton.tintColor
        evPosButton.isEnabled = evNegButton.isEnabled
        
        evLabel.text = exposureCompensation == nil ? "" : Dronelink.shared.formatEnum(name: "CameraExposureCompensation", value: exposureCompensation!.rawValue)
    }
}

extension MissionExecutorOffsetsViewController: DroneSessionManagerDelegate {
    public func onOpened(session: DroneSession) {
        self.session = session
        session.add(delegate: self)
        DispatchQueue.main.async {
            self.update()
        }
    }
    
    public func onClosed(session: DroneSession) {
        self.session = nil
        session.remove(delegate: self)
        DispatchQueue.main.async {
            self.update()
        }
    }
}

extension MissionExecutorOffsetsViewController: DroneSessionDelegate {
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
