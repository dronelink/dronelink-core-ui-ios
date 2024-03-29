//
//  DroneOffsetsWidget.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 2/6/20.
//  Copyright © 2020 Dronelink. All rights reserved.
//
import Foundation
import CoreLocation
import CoreMotion
import DronelinkCore
import MaterialComponents.MaterialPalettes
import MaterialComponents.MaterialButtons
import MaterialComponents.MaterialProgressView

public class DroneOffsetsWidget: CameraWidget {
    public enum Style: Int, CaseIterable {
        case altYaw = 0
        case position
        
        var display: String {
            switch self {
            case .altYaw: return "DroneOffsetsWidget.altitudeYaw".localized
            case .position: return "DroneOffsetsWidget.position".localized
            }
        }
    }
    
    public override var updateInterval: TimeInterval { 0.25 }
    
    public var styles: [Style] = Style.allCases
    
    private let debug = false
    private var styleSegmentedControl: UISegmentedControl!
    private let detailsLabel = UILabel()
    private let rcInputsToggleButton = UIButton(type: .custom)
    private let moreButton = UIButton(type: .custom)
    private let clearButton = UIButton(type: .custom)
    private let leftButton = MDCFloatingButton()
    private let rightButton = MDCFloatingButton()
    private let upButton = MDCFloatingButton()
    private let downButton = MDCFloatingButton()
    private let c1Button = MDCFloatingButton()
    private let c2Button = MDCFloatingButton()
    private let cLabel = UILabel()
    
    private var rcInputsEnabled = false
    private var rollVisible = false
    private var rollValue = 0
    private var style: Style { styles[styleSegmentedControl!.selectedSegmentIndex] }
    private var offsets: DroneOffsets {
        get { Dronelink.shared.droneOffsets }
        set (newOffsets) { Dronelink.shared.droneOffsets = newOffsets }
    }
    private var altimeter = CMAltimeter()
    private var relativeAltitudeUpdating = false
    private var relativeAltitudeActive = false
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        }
        
        view.addShadow()
        view.layer.cornerRadius = DronelinkUI.Constants.cornerRadius
        view.backgroundColor = DronelinkUI.Constants.overlayColor
        
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
        
        rcInputsToggleButton.tintColor = UIColor.white.withAlphaComponent(0.85)
        rcInputsToggleButton.setImage(DronelinkUI.loadImage(named: "rc"), for: .normal)
        rcInputsToggleButton.addTarget(self, action: #selector(onRCInputsToggle), for: .touchUpInside)
        view.addSubview(rcInputsToggleButton)
        
        moreButton.tintColor = UIColor.white.withAlphaComponent(0.85)
        moreButton.setImage(DronelinkUI.loadImage(named: "baseline_more_horiz_white_36pt"), for: .normal)
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
        configureButton(button: c1Button, image: "baseline_timeline_white_24pt", action: #selector(onC1(sender:)))
        configureButton(button: c2Button, image: "baseline_arrow_upward_white_24pt", color: style == .altYaw ? MDCPalette.purple.accent400 : MDCPalette.pink.accent400, action: #selector(onC2(sender:)))
        
        cLabel.textAlignment = .center
        cLabel.font = UIFont.boldSystemFont(ofSize: 14)
        cLabel.textColor = detailsLabel.textColor
        cLabel.minimumScaleFactor = 0.5
        cLabel.adjustsFontSizeToFitWidth = true
        view.addSubview(cLabel)
        
        update()
    }
    
    deinit {
        stopRelativeAltitudeUpdates()
    }
    
    func stopRelativeAltitudeUpdates() {
        if relativeAltitudeUpdating {
            altimeter.stopRelativeAltitudeUpdates()
            relativeAltitudeUpdating = false
            relativeAltitudeActive = false
        }
    }
    
    open override func onClosed(session: DroneSession) {
        super.onClosed(session: session)
        stopRelativeAltitudeUpdates()
    }
    
    open override func onMotorsChanged(session: DroneSession, value: Bool) {
        if !CMAltimeter.isRelativeAltitudeAvailable() {
            return
        }
        
        if value {
            //disabling this for now until we do more testing
//            relativeAltitudeUpdating = true
//            altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] altitude, error in
//                if let relativeAltitude = altitude?.relativeAltitude, self?.relativeAltitudeActive ?? false {
//                    self?.offsets.droneAltitude = -relativeAltitude.doubleValue
//                }
//            }
        }
        else {
            stopRelativeAltitudeUpdates()
        }
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
        
        styleSegmentedControl.snp.remakeConstraints { [weak self] make in
            make.height.equalTo(25)
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
            make.top.equalToSuperview().offset(8)
        }
        
        rcInputsToggleButton.snp.remakeConstraints { [weak self] make in
            make.height.equalTo(styleSegmentedControl)
            make.width.equalTo(moreButton.snp.height)
            make.left.equalTo(styleSegmentedControl)
            make.top.equalTo(styleSegmentedControl.snp.bottom).offset(defaultPadding)
        }
        
        moreButton.snp.remakeConstraints { [weak self] make in
            make.height.equalTo(styleSegmentedControl)
            make.width.equalTo(moreButton.snp.height)
            make.left.equalTo(rcInputsToggleButton)
            make.top.equalTo(rcInputsToggleButton.snp.bottom).offset(defaultPadding)
        }
        
        clearButton.snp.remakeConstraints { [weak self] make in
            make.height.equalTo(styleSegmentedControl)
            make.width.equalTo(clearButton.snp.height)
            make.right.equalTo(styleSegmentedControl)
            make.top.equalTo(styleSegmentedControl.snp.bottom).offset(defaultPadding)
        }
        
        detailsLabel.snp.remakeConstraints { [weak self] make in
            make.height.equalTo(styleSegmentedControl)
            make.left.equalTo(moreButton.snp.right).offset(5)
            make.right.equalTo(clearButton.snp.left).offset(-5)
            make.top.equalTo(styleSegmentedControl.snp.bottom).offset(defaultPadding)
        }
        
        upButton.snp.remakeConstraints { [weak self] make in
            make.height.equalTo(buttonSize)
            make.width.equalTo(buttonSize)
            make.top.equalTo(detailsLabel.snp.bottom).offset(defaultPadding)
            make.centerX.equalToSuperview()
        }
        
        downButton.snp.remakeConstraints { [weak self] make in
            make.height.equalTo(buttonSize)
            make.width.equalTo(buttonSize)
            make.top.equalTo(upButton.snp.bottom).offset(20)
            make.centerX.equalTo(upButton)
        }
        
        leftButton.snp.remakeConstraints { [weak self] make in
            make.height.equalTo(buttonSize)
            make.width.equalTo(buttonSize)
            make.top.equalTo(upButton).offset(33)
            make.right.equalTo(upButton.snp.left).offset(-defaultPadding)
        }
        
        rightButton.snp.remakeConstraints { [weak self] make in
            make.height.equalTo(buttonSize)
            make.width.equalTo(buttonSize)
            make.centerY.equalTo(leftButton)
            make.left.equalTo(upButton.snp.right).offset(defaultPadding)
        }

        c1Button.snp.remakeConstraints { [weak self] make in
            make.height.equalTo(buttonSize)
            make.width.equalTo(buttonSize)
            make.bottom.equalToSuperview().offset(-defaultPadding)
            make.left.equalToSuperview().offset(defaultPadding)
        }
        
        c2Button.snp.remakeConstraints { [weak self] make in
            make.height.equalTo(buttonSize)
            make.width.equalTo(buttonSize)
            make.bottom.equalToSuperview().offset(-defaultPadding)
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
        
    @objc func onStyleChanged(sender: Any) {
        updateRoll(visible: false)
    }
    
    func updateRoll(visible: Bool) {
        rollVisible = visible
        if rollVisible {
            configureButton(button: leftButton, image: "baseline_rotate_left_white_36pt", action: #selector(onLeft(sender:)))
            configureButton(button: rightButton, image: "baseline_rotate_right_white_36pt", action: #selector(onRight(sender:)))
            configureButton(button: c2Button, image: "baseline_check_white_24pt", color: MDCPalette.lightBlue.accent400, action: #selector(onC2(sender:)))
        }
        else {
            configureButton(button: leftButton, image: "baseline_arrow_left_white_36pt", action: #selector(onLeft(sender:)))
            configureButton(button: rightButton, image: "baseline_arrow_right_white_36pt", action: #selector(onRight(sender:)))
            configureButton(button: c1Button, image: "baseline_timeline_white_24pt", action: #selector(onC1(sender:)))
            configureButton(button: c2Button, image: "baseline_arrow_upward_white_24pt", color: style == .altYaw ? MDCPalette.purple.accent400 : MDCPalette.pink.accent400, action: #selector(onC2(sender:)))
        }
        
        if style == .altYaw {
            styleSegmentedControl.setTitle(rollVisible ? "DroneOffsetsWidget.rollTrim".localized.uppercased() : style.display, forSegmentAt: style.rawValue)
        }
        
        update()
    }
    
    func updateRoll(value: Int) {
        rollValue = value
        session?.drone.gimbal(channel: channelResolved)?.fineTune(roll: (Double(rollValue) / 10).convertDegreesToRadians)
    }
    
    @objc func onRCInputsToggle(sender: Any) {
        rcInputsEnabled = !rcInputsEnabled
        if rcInputsEnabled {
            DronelinkUI.shared.showSnackbar(text: "DroneOffsetsWidget.rc.inputs".localized)
        }
        update()
    }
    
    @objc func onMore(sender: Any) {
        let channel = channelResolved
        let alert = UIAlertController(title: "DroneOffsetsWidget.more".localized, message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.sourceView = sender as? UIView
        alert.addAction(UIAlertAction(title: "DroneOffsetsWidget.levelGimbal".localized, style: .default , handler:{ [weak self] _ in
            var command = Kernel.OrientationGimbalCommand(channel: channel)
            command.orientation.x = 0
            try? self?.session?.add(command: command)
        }))
        
        alert.addAction(UIAlertAction(title: "DroneOffsetsWidget.nadirGimbal".localized, style: .default , handler:{ [weak self] _ in
            var command = Kernel.OrientationGimbalCommand(channel: channel)
            command.orientation.x = -90.convertDegreesToRadians
            try? self?.session?.add(command: command)
        }))
        
        alert.addAction(UIAlertAction(title: "DroneOffsetsWidget.resetGimbal".localized, style: .default , handler:{ [weak self] _ in
            self?.session?.drone.gimbal(channel: channel)?.reset()
        }))
        
        alert.addAction(UIAlertAction(title: "DroneOffsetsWidget.rollTrim".localized, style: .default , handler:{ [weak self] _ in
            self?.updateRoll(visible: true)
        }))
        
        if let serialNumber = session?.serialNumber {
            alert.addAction(UIAlertAction(title: "DroneOffsetsWidget.clearCameraFocusCalibrations".localized, style: .default , handler:{ [weak self] _ in
                let cleared = Dronelink.shared.clearCameraFocusCalibrations(serialNumber: serialNumber)
                DronelinkUI.shared.showSnackbar(text: String(format: "DroneOffsetsWidget.clearCameraFocusCalibrations.finished".localized, "\(cleared)"))
            }))
        }
        
        alert.addAction(UIAlertAction(title: "dismiss".localized, style: .cancel, handler: { _ in
            
        }))

        present(alert, animated: true)
    }
    
    @objc func onClear(sender: Any) {
        if rollVisible {
            updateRoll(value: 0)
        }
        else {
            switch style {
            case .altYaw:
                relativeAltitudeActive = false
                offsets.droneAltitude = 0
                offsets.droneYaw = 0
                break
            
            case .position:
                offsets.droneCoordinate = Kernel.Vector2()
                break
            }
        }

        update()
    }
    
    @objc func onLeft(sender: Any) {
        guard let session = session else {
            return
        }
        
        if rollVisible {
            updateRoll(value: rollValue - 1)
        }
        else {
            switch style {
            case .altYaw:
                offsets.droneYaw += -3.0.convertDegreesToRadians
                break
            
            case .position:
                guard let state = session.state?.value else {
                    return
                }
                
                offsets.droneCoordinate = offsets.droneCoordinate.add(
                    vector: Kernel.Vector2(
                        direction: state.orientation.yaw - (Double.pi / 2),
                        magnitude: 1.0.convertFeetToMeters))
                break
            }
        }
        
        update()
    }
    
    @objc func onRight(sender: Any) {
        guard let session = session else {
            return
        }
        
        if rollVisible {
            updateRoll(value: rollValue + 1)
        }
        else {
            switch style {
            case .altYaw:
                offsets.droneYaw += 3.0.convertDegreesToRadians
                break
            
            case .position:
                guard let state = session.state?.value else {
                    return
                }
                
                offsets.droneCoordinate = offsets.droneCoordinate.add(
                    vector: Kernel.Vector2(
                        direction: state.orientation.yaw + (Double.pi / 2),
                        magnitude: 1.0.convertFeetToMeters))
                break
            }
        }
        update()
    }
    
    func incrementDroneAltitudeOffset(_ value: Double) {
        relativeAltitudeActive = false
        offsets.droneAltitude += value
    }
    
    @objc func onUp(sender: Any) {
        guard let session = session else {
            return
        }
        
        switch style {
        case .altYaw:
            incrementDroneAltitudeOffset(1.0.convertFeetToMeters)
            break
        
        case .position:
            guard let state = session.state?.value else {
                return
            }
            
            offsets.droneCoordinate = offsets.droneCoordinate.add(
                vector: Kernel.Vector2(
                    direction: state.orientation.yaw,
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
            incrementDroneAltitudeOffset(-1.0.convertFeetToMeters)
            break
        
        case .position:
            guard let state = session.state?.value else {
                return
            }
            
            offsets.droneCoordinate = offsets.droneCoordinate.add(
                vector: Kernel.Vector2(
                    direction: state.orientation.yaw + Double.pi,
                    magnitude: 1.0.convertFeetToMeters))
            break
        }
        
        update()
    }
    
    @objc func onC1(sender: Any) {
        switch style {
        case .altYaw:
            if relativeAltitudeActive {
                DronelinkUI.shared.showSnackbar(text: "DroneOffsetsWidget.relative.altitude.disabled".localized)
            }
            else {
                DronelinkUI.shared.showSnackbar(text: "DroneOffsetsWidget.relative.altitude.enabled".localized)
            }
            relativeAltitudeActive = !relativeAltitudeActive
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
        if rollVisible {
            updateRoll(visible: false)
        }
        else {
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
                
                offsets.droneCoordinate = Kernel.Vector2(
                    direction: reference.bearing(to: current),
                    magnitude: reference.distance(to: current)
                )
                break
            }
        }
        update()
    }
    
    @objc open override func update() {
        super.update()
        
        upButton.isEnabled = session != nil
        downButton.isEnabled = upButton.isEnabled
        leftButton.isEnabled = upButton.isEnabled
        rightButton.isEnabled = upButton.isEnabled
        rcInputsToggleButton.tintColor = rcInputsEnabled ? DronelinkUI.Constants.secondaryColor : UIColor.white

        if rollVisible {
            c1Button.isHidden = true
            c2Button.isHidden = false
            leftButton.isHidden = false
            rightButton.isHidden = false
            upButton.isHidden = true
            downButton.isHidden = true
            rcInputsToggleButton.isHidden = true
            moreButton.isHidden = true
            clearButton.isHidden = rollValue == 0
            detailsLabel.text = clearButton.isHidden ? "" : "\(Double(rollValue) / 10)"
            c2Button.isEnabled = upButton.isEnabled
        }
        else {
            switch style {
            case .altYaw:
                c1Button.setBackgroundColor(((relativeAltitudeActive ? MDCPalette.amber.accent700 : nil) ?? UIColor.darkGray).withAlphaComponent(0.85))
                c1Button.isHidden = !relativeAltitudeUpdating
                c2Button.isHidden = !debug
                leftButton.isHidden = false
                rightButton.isHidden = false
                upButton.isHidden = false
                downButton.isHidden = false
                
                var details: [String] = []
                if offsets.droneYaw != 0 {
                    details.append(Dronelink.shared.format(formatter: "angle", value: offsets.droneYaw, extraParams: [false]))
                }

                if offsets.droneAltitude != 0 {
                    details.append(Dronelink.shared.format(formatter: "altitude", value: offsets.droneAltitude))
                }

                rcInputsToggleButton.isHidden = session?.remoteControllerState(channel: 0) == nil
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

                c1Button.isEnabled = true
                c2Button.isEnabled = cLabel.text != nil
                break

            case .position:
                c1Button.isHidden = !debug
                c2Button.isHidden = false
                leftButton.isHidden = false
                rightButton.isHidden = false
                upButton.isHidden = false
                downButton.isHidden = false
                rcInputsToggleButton.isHidden = session?.remoteControllerState(channel: 0) == nil
                moreButton.isHidden = session == nil || UIDevice.current.userInterfaceIdiom == .pad
                clearButton.isHidden = offsets.droneCoordinate.magnitude == 0
                detailsLabel.text = clearButton.isHidden ? "" : display(vector: offsets.droneCoordinate)

                if let session = session,
                    let reference = offsets.droneCoordinateReference,
                    let current = session.state?.value.location?.coordinate {
                    cLabel.text = display(vector: Kernel.Vector2(
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
        }
        
        if rcInputsEnabled, Dronelink.shared.missionExecutor?.engaged ?? false,
            let remoteControllerState = session?.remoteControllerState(channel: 0)?.value {
            let deadband = 0.15
            
            switch style {
            case .altYaw:
                let yawPercent = remoteControllerState.leftStick.x
                if abs(yawPercent) > deadband {
                    offsets.droneYaw += (1.0 * yawPercent).convertDegreesToRadians
                }

                let altitudePercent = remoteControllerState.leftStick.y
                if abs(altitudePercent) > deadband {
                    incrementDroneAltitudeOffset((0.5 * altitudePercent).convertFeetToMeters)
                }
                break
                    
            case .position:
                let positionXPercent = remoteControllerState.rightStick.x
                if abs(positionXPercent) > deadband {
                    guard let state = session?.state?.value else {
                        return
                    }
                    
                    offsets.droneCoordinate = offsets.droneCoordinate.add(
                        vector: Kernel.Vector2(
                            direction: state.orientation.yaw + (positionXPercent >= 0 ? (Double.pi / 2) : -(Double.pi / 2)),
                            magnitude: (0.4 * abs(positionXPercent)).convertFeetToMeters))
                }
                
                let positionYPercent = remoteControllerState.rightStick.y
                if abs(positionYPercent) > deadband {
                    guard let state = session?.state?.value else {
                        return
                    }
                    
                    offsets.droneCoordinate = offsets.droneCoordinate.add(
                        vector: Kernel.Vector2(
                            direction: state.orientation.yaw + (positionYPercent >= 0 ? 0 : Double.pi),
                            magnitude: (0.4 * abs(positionYPercent)).convertFeetToMeters))
                }
                break
            }
        }
    }
    
    func display(vector: Kernel.Vector2) -> String {
        return "\(Dronelink.shared.format(formatter: "angle", value: vector.direction)) → \(Dronelink.shared.format(formatter: "distance", value: vector.magnitude))"
    }
}
