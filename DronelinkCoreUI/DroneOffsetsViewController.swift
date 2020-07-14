//
//  DroneOffsetsViewController.swift
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

public class DroneOffsetsViewController: UIViewController {
    public enum Style: Int, CaseIterable {
        case altYaw = 0
        case position
        
        var display: String {
            switch self {
            case .altYaw: return "DroneOffsetsViewController.altitudeYaw".localized
            case .position: return "DroneOffsetsViewController.position".localized
            }
        }
    }
    
    public static func create(droneSessionManager: DroneSessionManager, styles: [Style] = Style.allCases) -> DroneOffsetsViewController {
        let droneOffsetsViewController = DroneOffsetsViewController()
        droneOffsetsViewController.styles = styles
        droneOffsetsViewController.droneSessionManager = droneSessionManager
        return droneOffsetsViewController
    }
    
    private var styles: [Style] = Style.allCases
    private var droneSessionManager: DroneSessionManager!
    private var session: DroneSession?
    
    private let debug = false
    private var styleSegmentedControl: UISegmentedControl!
    private let detailsLabel = UILabel()
    private let moreButton = UIButton(type: .custom)
    private let clearButton = UIButton(type: .custom)
    private let leftButton = MDCFloatingButton()
    private let rightButton = MDCFloatingButton()
    private let upButton = MDCFloatingButton()
    private let downButton = MDCFloatingButton()
    private let c1Button = MDCFloatingButton()
    private let c2Button = MDCFloatingButton()
    private let cLabel = UILabel()
    
    private let updateInterval: TimeInterval = 0.25
    private var updateTimer: Timer?
    private var style: Style { styles[styleSegmentedControl!.selectedSegmentIndex] }
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
        
        styleSegmentedControl = UISegmentedControl(items: styles.map({ $0.display }))
        styleSegmentedControl.selectedSegmentIndex = 0
        styleSegmentedControl.addTarget(self, action:  #selector(onStyleChanged(sender:)), for: .valueChanged)
        view.addSubview(styleSegmentedControl)
        
        detailsLabel.textAlignment = .center
        detailsLabel.font = UIFont.boldSystemFont(ofSize: 16)
        detailsLabel.textColor = UIColor.white
        detailsLabel.minimumScaleFactor = 0.5
        detailsLabel.adjustsFontSizeToFitWidth = true
        view.addSubview(detailsLabel)
        
        moreButton.tintColor = UIColor.white.withAlphaComponent(0.85)
        moreButton.setImage(DronelinkUI.loadImage(named: "outline_more_white_36pt"), for: .normal)
        moreButton.addTarget(self, action: #selector(onMore), for: .touchUpInside)
        view.addSubview(moreButton)
        
        clearButton.tintColor = UIColor.white.withAlphaComponent(0.85)
        clearButton.setImage(DronelinkUI.loadImage(named: "baseline_cancel_white_36pt"), for: .normal)
        clearButton.addTarget(self, action: #selector(onClear), for: .touchUpInside)
        view.addSubview(clearButton)
        
        configureButton(button: leftButton, image: "baseline_arrow_left_white_36pt", action: #selector(onLeft(sender:)))
        configureButton(button: rightButton, image: "baseline_arrow_right_white_36pt", action: #selector(onRight(sender:)))
        configureButton(button: upButton, image: "baseline_arrow_drop_up_white_36pt", action: #selector(onUp(sender:)))
        configureButton(button: downButton, image: "baseline_arrow_drop_down_white_36pt", action: #selector(onDown(sender:)))
        configureButton(button: c1Button, image: "baseline_check_white_24pt", color: style == .altYaw ? MDCPalette.green.accent400 : MDCPalette.lightBlue.accent400, action: #selector(onC1(sender:)))
        configureButton(button: c2Button, image: "baseline_arrow_upward_white_24pt", color: style == .altYaw ? MDCPalette.purple.accent400 : MDCPalette.pink.accent400, action: #selector(onC2(sender:)))
        
        cLabel.textAlignment = .center
        cLabel.font = UIFont.boldSystemFont(ofSize: 14)
        cLabel.textColor = detailsLabel.textColor
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
        
        styleSegmentedControl.snp.remakeConstraints { make in
            make.height.equalTo(25)
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
            make.top.equalToSuperview().offset(8)
        }
        
        moreButton.snp.remakeConstraints { make in
            make.height.equalTo(styleSegmentedControl)
            make.width.equalTo(moreButton.snp.height)
            make.left.equalTo(styleSegmentedControl)
            make.top.equalTo(styleSegmentedControl.snp.bottom).offset(defaultPadding)
        }
        
        clearButton.snp.remakeConstraints { make in
            make.height.equalTo(styleSegmentedControl)
            make.width.equalTo(clearButton.snp.height)
            make.right.equalTo(styleSegmentedControl)
            make.top.equalTo(styleSegmentedControl.snp.bottom).offset(defaultPadding)
        }
        
        detailsLabel.snp.remakeConstraints { make in
            make.height.equalTo(styleSegmentedControl)
            make.left.equalTo(moreButton.snp.right).offset(5)
            make.right.equalTo(clearButton.snp.left).offset(-5)
            make.top.equalTo(styleSegmentedControl.snp.bottom).offset(defaultPadding)
        }
        
        upButton.snp.remakeConstraints { make in
            make.height.equalTo(buttonSize)
            make.width.equalTo(buttonSize)
            make.top.equalTo(detailsLabel.snp.bottom).offset(defaultPadding)
            make.centerX.equalToSuperview()
        }
        
        downButton.snp.remakeConstraints { make in
            make.height.equalTo(buttonSize)
            make.width.equalTo(buttonSize)
            make.top.equalTo(upButton.snp.bottom).offset(20)
            make.centerX.equalTo(upButton)
        }
        
        leftButton.snp.remakeConstraints { make in
            make.height.equalTo(buttonSize)
            make.width.equalTo(buttonSize)
            make.top.equalTo(upButton).offset(33)
            make.right.equalTo(upButton.snp.left).offset(-defaultPadding)
        }
        
        rightButton.snp.remakeConstraints { make in
            make.height.equalTo(buttonSize)
            make.width.equalTo(buttonSize)
            make.centerY.equalTo(leftButton)
            make.left.equalTo(upButton.snp.right).offset(defaultPadding)
        }

        c1Button.snp.remakeConstraints { make in
            make.height.equalTo(buttonSize)
            make.width.equalTo(buttonSize)
            make.bottom.equalToSuperview().offset(-defaultPadding)
            make.left.equalToSuperview().offset(defaultPadding)
        }
        
        c2Button.snp.remakeConstraints { make in
            make.height.equalTo(buttonSize)
            make.width.equalTo(buttonSize)
            make.bottom.equalToSuperview().offset(-defaultPadding)
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
        
    @objc func onStyleChanged(sender: Any) {
        configureButton(button: c1Button, image: "baseline_check_white_24pt", color: style == .altYaw ? MDCPalette.green.accent400 : MDCPalette.lightBlue.accent400, action: #selector(onC1(sender:)))
        configureButton(button: c2Button, image: "baseline_arrow_upward_white_24pt", color: style == .altYaw ? MDCPalette.purple.accent400 : MDCPalette.pink.accent400, action: #selector(onC2(sender:)))
        update()
    }
    
    @objc func onMore(sender: Any) {
        let alert = UIAlertController(title: "DroneOffsetsViewController.more".localized, message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.sourceView = sender as? UIView
        alert.addAction(UIAlertAction(title: "DroneOffsetsViewController.levelGimbal".localized, style: .default , handler:{ _ in
            var command = Mission.OrientationGimbalCommand()
            command.orientation.x = 0
            try? self.session?.add(command: command)
        }))
        
        alert.addAction(UIAlertAction(title: "DroneOffsetsViewController.nadirGimbal".localized, style: .default , handler:{ _ in
            var command = Mission.OrientationGimbalCommand()
            command.orientation.x = -90.convertDegreesToRadians
            try? self.session?.add(command: command)
        }))
        
        alert.addAction(UIAlertAction(title: "DroneOffsetsViewController.resetGimbal".localized, style: .default , handler:{ _ in
            self.session?.drone.gimbal(channel: 0)?.reset()
        }))
        
        alert.addAction(UIAlertAction(title: "dismiss".localized, style: .cancel, handler: { _ in
            
        }))

        present(alert, animated: true)
    }
    
    @objc func onClear(sender: Any) {
        switch style {
        case .altYaw:
            offsets.droneAltitude = 0
            offsets.droneYaw = 0
            break
        
        case .position:
            offsets.droneCoordinate = Mission.Vector2()
            break
        }

        update()
    }
    
    @objc func onLeft(sender: Any) {
        guard let session = session else {
            return
        }
        
        switch style {
        case .altYaw:
            offsets.droneYaw += -3.0.convertDegreesToRadians
            break
        
        case .position:
            guard let state = session.state?.value else {
                return
            }
            
            offsets.droneCoordinate = offsets.droneCoordinate.add(
                vector: Mission.Vector2(
                    direction: state.missionOrientation.yaw - (Double.pi / 2),
                    magnitude: 1.0.convertFeetToMeters))
            break
        }
        
        update()
    }
    
    @objc func onRight(sender: Any) {
        guard let session = session else {
            return
        }
        
        switch style {
        case .altYaw:
            offsets.droneYaw += 3.0.convertDegreesToRadians
            break
        
        case .position:
            guard let state = session.state?.value else {
                return
            }
            
            offsets.droneCoordinate = offsets.droneCoordinate.add(
                vector: Mission.Vector2(
                    direction: state.missionOrientation.yaw + (Double.pi / 2),
                    magnitude: 1.0.convertFeetToMeters))
            break
        }
        
        update()
    }
    
    @objc func onUp(sender: Any) {
        guard let session = session else {
            return
        }
        
        switch style {
        case .altYaw:
            offsets.droneAltitude += 1.0.convertFeetToMeters
            break
        
        case .position:
            guard let state = session.state?.value else {
                return
            }
            
            offsets.droneCoordinate = offsets.droneCoordinate.add(
                vector: Mission.Vector2(
                    direction: state.missionOrientation.yaw,
                    magnitude: 1.0.convertFeetToMeters))
            break
        }
        
        update()
    }
    
    @objc func onDown(sender: Any) {
        guard let session = session else {
            return
        }
        
        switch style {
        case .altYaw:
            offsets.droneAltitude += -1.0.convertFeetToMeters
            break
        
        case .position:
            guard let state = session.state?.value else {
                return
            }
            
            offsets.droneCoordinate = offsets.droneCoordinate.add(
                vector: Mission.Vector2(
                    direction: state.missionOrientation.yaw + Double.pi,
                    magnitude: 1.0.convertFeetToMeters))
            break
        }
        
        update()
    }
    
    @objc func onC1(sender: Any) {
        switch style {
        case .altYaw:
            guard let altitude = session?.state?.value.altitude else {
                return
            }
            
            offsets.droneAltitudeReference = altitude
            break
        
        case .position:
            guard let coordinate = session?.state?.value.location?.coordinate else {
                return
            }
            
            offsets.droneCoordinateReference = coordinate
            break
        }
        update()
    }
    
    @objc func onC2(sender: Any) {
        switch style {
        case .altYaw:
            guard
                let session = session,
                let reference = offsets.droneAltitudeReference,
                let current = session.state?.value.altitude
            else {
                return
            }
            
            offsets.droneAltitude = reference - current
            break
        
        case .position:
            guard
                let session = session,
                let reference = offsets.droneCoordinateReference,
                let current = session.state?.value.location?.coordinate
            else {
                return
            }
            
            offsets.droneCoordinate = Mission.Vector2(
                direction: reference.bearing(to: current),
                magnitude: reference.distance(to: current)
            )
            break
        }
        update()
    }
    
    @objc func update() {
        upButton.isEnabled = session != nil
        downButton.isEnabled = upButton.isEnabled
        leftButton.isEnabled = upButton.isEnabled
        rightButton.isEnabled = upButton.isEnabled

        switch style {
        case .altYaw:
            c1Button.isHidden = !debug
            c2Button.isHidden = !debug
            leftButton.isHidden = false
            rightButton.isHidden = false
            
            var details: [String] = []
            if offsets.droneYaw != 0 {
                details.append(Dronelink.shared.format(formatter: "angle", value: offsets.droneYaw, extraParams: [false]))
            }

            if offsets.droneAltitude != 0 {
                details.append(Dronelink.shared.format(formatter: "altitude", value: offsets.droneAltitude))
            }

            moreButton.isHidden = session == nil
            clearButton.isHidden = details.count == 0
            detailsLabel.text = details.joined(separator: " / ")

            if let session = session,
                let reference = offsets.droneAltitudeReference,
                let current = session.state?.value.altitude {
                cLabel.text = Dronelink.shared.format(formatter: "distance", value: reference - current)
            }
            else {
                cLabel.text = nil
            }

            c1Button.isEnabled = session?.state?.value.altitude != nil && !(Dronelink.shared.missionExecutor?.engaged ?? false)
            c2Button.isEnabled = c1Button.isEnabled && cLabel.text != nil
            break

        case .position:
            c1Button.isHidden = !debug
            c2Button.isHidden = false
            leftButton.isHidden = true
            rightButton.isHidden = true
            moreButton.isHidden = session == nil || UIDevice.current.userInterfaceIdiom == .pad
            clearButton.isHidden = offsets.droneCoordinate.magnitude == 0
            detailsLabel.text = clearButton.isHidden ? "" : display(vector: offsets.droneCoordinate)

            if let session = session,
                let reference = offsets.droneCoordinateReference,
                let current = session.state?.value.location?.coordinate {
                cLabel.text = display(vector: Mission.Vector2(
                    direction: reference.bearing(to: current),
                    magnitude: reference.distance(to: current)))
            }
            else {
                cLabel.text = nil
            }

            c1Button.isEnabled = session?.state?.value.location != nil && !(Dronelink.shared.missionExecutor?.engaged ?? false)
            c2Button.isEnabled = c1Button.isEnabled && cLabel.text != nil
            break
        }
        
        if Dronelink.shared.missionExecutor?.engaged ?? false,
            let remoteControllerState = session?.remoteControllerState(channel: 0)?.value {
            let deadband = 0.2
            
            let yawPercent = remoteControllerState.leftStickState.horizontal
            if abs(yawPercent) > deadband {
                offsets.droneYaw += (1.0 * yawPercent).convertDegreesToRadians
            }

            let altitudePercent = remoteControllerState.leftStickState.vertical
            if abs(altitudePercent) > deadband {
                offsets.droneAltitude += (0.25 * altitudePercent).convertFeetToMeters
            }
            
            
            let positionPercent = remoteControllerState.rightStickState.vertical
            if abs(positionPercent) > deadband {
                guard let state = session?.state?.value else {
                    return
                }
                
                offsets.droneCoordinate = offsets.droneCoordinate.add(
                    vector: Mission.Vector2(
                        direction: state.missionOrientation.yaw + (positionPercent >= 0 ? 0 : Double.pi),
                        magnitude: (0.25 * abs(positionPercent)).convertFeetToMeters))
            }
        }
    }
    
    func display(vector: Mission.Vector2) -> String {
        return "\(Dronelink.shared.format(formatter: "angle", value: vector.direction)) → \(Dronelink.shared.format(formatter: "distance", value: vector.magnitude))"
    }
}

extension DroneOffsetsViewController: DroneSessionManagerDelegate {
    public func onOpened(session: DroneSession) {
        self.session = session
    }
    
    public func onClosed(session: DroneSession) {
        self.session = nil
    }
}
