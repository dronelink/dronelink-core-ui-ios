//
//  CameraFocusCalibrationWidget.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 6/8/21.
//  Copyright © 2021 Dronelink. All rights reserved.
//
import Foundation
import CoreLocation
import DronelinkCore
import MaterialComponents.MaterialButtons

public class CameraFocusCalibrationWidget: UpdatableWidget, ExecutorWidget {
    public override var updateInterval: TimeInterval { 0.1 }
    
    public let layout: DynamicSizeWidgetLayout = .medium
    
    public var preferredSize: CGSize { CGSize(width: 350, height: 200) }
    
    private let headerBackgroundView = UIView()
    private let footerBackgroundView = UIView()
    private let titleImageView = UIImageView()
    private let titleLabel = UILabel()
    private let typeSegmentedControl = UISegmentedControl()
    private let markReferenceButton = MDCButton()
    private let referenceLabel = UILabel()
    private let detailsLabel = UILabel()
    private let dismissButton = UIButton(type: .custom)
    private let titleImage = DronelinkUI.loadImage(named: "baseline_center_focus_strong_white_36pt")
    private let cancelImage = DronelinkUI.loadImage(named: "baseline_close_white_36pt")
    
    private let referenceInvalidColor = MDCPalette.red.accent700
    private let referenceValidColor = MDCPalette.green.accent700
    
    public var calibration: Kernel.CameraFocusCalibration?
    private var referenceLocation: CLLocation?
    private var previousCameraFocusRingValue: Double? = nil
    private var previousCameraBusyFocused = false
    private var cameraFocusRingValues: [Double] = []
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        }
        
        view.addShadow()
        view.layer.cornerRadius = DronelinkUI.Constants.cornerRadius
        view.clipsToBounds = true
        view.backgroundColor = DronelinkUI.Constants.overlayColor
        
        headerBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.addSubview(headerBackgroundView)
        headerBackgroundView.snp.makeConstraints { [weak self] make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(43)
        }
        
        footerBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.addSubview(footerBackgroundView)
        footerBackgroundView.snp.makeConstraints { [weak self] make in
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(52)
        }
        
        dismissButton.tintColor = UIColor.white
        dismissButton.setImage(cancelImage, for: .normal)
        dismissButton.addTarget(self, action: #selector(onDismiss), for: .touchUpInside)
        view.addSubview(dismissButton)
        dismissButton.snp.makeConstraints { [weak self] make in
            make.height.equalTo(24)
            make.width.equalTo(dismissButton.snp.height)
            make.top.equalToSuperview().offset(defaultPadding)
            make.right.equalToSuperview().offset(-defaultPadding)
        }
        
        titleImageView.image = titleImage
        titleImageView.tintColor = UIColor.white
        view.addSubview(titleImageView)
        titleImageView.snp.makeConstraints { [weak self] make in
            make.height.equalTo(24)
            make.width.equalTo(titleImageView.snp.height)
            make.top.equalToSuperview().offset(defaultPadding)
            make.left.equalToSuperview().offset(defaultPadding)
        }
        
        titleLabel.text = "CameraFocusCalibrationWidget.title".localized
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textColor = UIColor.white
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { [weak self] make in
            make.height.equalTo(25)
            make.left.equalTo(titleImageView.snp.right).offset(defaultPadding)
            make.right.equalTo(dismissButton.snp.left).offset(-defaultPadding)
            make.top.equalTo(titleImageView.snp.top)
        }
        
        typeSegmentedControl.insertSegment(withTitle: "CameraFocusCalibrationWidget.type.distance".localized, at: 0, animated: false)
        typeSegmentedControl.insertSegment(withTitle: "CameraFocusCalibrationWidget.type.altitude".localized, at: 1, animated: false)
        typeSegmentedControl.selectedSegmentIndex = 0
        typeSegmentedControl.addTarget(self, action:  #selector(onTypeChanged(sender:)), for: .valueChanged)
        view.addSubview(typeSegmentedControl)
        typeSegmentedControl.snp.remakeConstraints { [weak self] make in
            make.left.equalToSuperview().offset(defaultPadding)
            make.right.equalToSuperview().offset(-defaultPadding)
            make.top.equalTo(titleLabel.snp.bottom).offset(defaultPadding * 1.5)
            make.height.equalTo(28)
        }
        
        let buttonHeight = 32
        
        let scheme = MDCContainerScheme()
        scheme.colorScheme = MDCSemanticColorScheme(defaults: .materialDark201907)
        scheme.colorScheme.primaryColor = UIColor.darkGray
        markReferenceButton.applyContainedTheme(withScheme: scheme)
        markReferenceButton.translatesAutoresizingMaskIntoConstraints = false
        markReferenceButton.setImageTintColor(.white, for: .normal)
        markReferenceButton.setTitle("CameraFocusCalibrationWidget.mark.reference.title".localized, for: .normal)
        markReferenceButton.setTitleColor(.white, for: .normal)
        markReferenceButton.addTarget(self, action: #selector(onMarkReference(sender:)), for: .touchUpInside)
        view.addSubview(markReferenceButton)
        markReferenceButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-defaultPadding)
            make.left.equalToSuperview().offset(defaultPadding)
            make.width.equalTo(160)
            make.height.equalTo(buttonHeight)
        }
        
        referenceLabel.font = UIFont.boldSystemFont(ofSize: 14)
        referenceLabel.textColor = UIColor.white
        referenceLabel.numberOfLines = 1
        referenceLabel.lineBreakMode = .byTruncatingTail
        referenceLabel.textAlignment = .center
        referenceLabel.layer.masksToBounds = true
        referenceLabel.layer.cornerRadius = 10
        view.addSubview(referenceLabel)
        
        detailsLabel.font = UIFont.boldSystemFont(ofSize: 14)
        detailsLabel.textColor = UIColor.white
        detailsLabel.numberOfLines = 0
        detailsLabel.lineBreakMode = .byWordWrapping
        view.addSubview(detailsLabel)
        detailsLabel.snp.makeConstraints { [weak self] make in
            make.top.equalTo(typeSegmentedControl.snp.bottom)
            make.left.equalToSuperview().offset(defaultPadding * 2)
            make.right.equalToSuperview().offset(-defaultPadding * 2)
            make.bottom.equalTo(markReferenceButton.snp.top).offset(-defaultPadding * 0.5)
        }
        
        reset()
    }
    
    func reset() {
        referenceLocation = nil
        cameraFocusRingValues.removeAll()
        try? session?.add(command: Kernel.OrientationGimbalCommand(orientation: Kernel.Orientation3Optional(x: typeSegmentedControl.selectedSegmentIndex == 0 ? 0 : -90.convertDegreesToRadians)))
        DispatchQueue.main.async { [weak self] in
            self?.view.setNeedsUpdateConstraints()
        }
    }
    
    public override func updateViewConstraints() {
        super.updateViewConstraints()
        
        referenceLabel.snp.remakeConstraints { [weak self] make in
            make.height.equalTo(28)
            if typeSegmentedControl.selectedSegmentIndex == 0 {
                make.left.equalTo(markReferenceButton.snp.right).offset(defaultPadding)
            }
            else {
                make.left.equalToSuperview().offset(defaultPadding)
            }
            make.right.equalToSuperview().offset(-defaultPadding)
            make.centerY.equalTo(markReferenceButton)
        }
    }
    
    @objc func onTypeChanged(sender: Any) {
        markReferenceButton.isHidden = typeSegmentedControl.selectedSegmentIndex == 1
        reset()
    }
    
    @objc func onMarkReference(sender: Any) {
        referenceLocation = session?.state?.value.location
        cameraFocusRingValues.removeAll()
    }
    
    @objc func onDismiss() {
        if let calibration = calibration {
            Dronelink.shared.update(cameraFocusCalibration: calibration)
        }
    }
    
    override open func onOpened(session: DroneSession) {
        super.onOpened(session: session)
        
        reset()
        
        try? session.add(command: Kernel.StopCaptureCameraCommand())
        try? session.add(command: Kernel.ModeCameraCommand(mode: .photo))
        try? session.add(command: Kernel.FocusModeCameraCommand(focusMode: .auto))
    }
    
    @objc open override func update() {
        super.update()
        
        guard var calibration = calibration else { return }
        
        markReferenceButton.isEnabled = false
        
        referenceLabel.text = ""
        referenceLabel.backgroundColor = UIColor.clear
        guard let session = session else {
            detailsLabel.text = "CameraFocusCalibrationWidget.drone.unavailable".localized
            return
        }
        
        guard let serialNumber = session.serialNumber else {
            detailsLabel.text = "CameraFocusCalibrationWidget.serial.number.unavailable".localized
            return
        }
        
        guard
            let gimbalState = session.gimbalState(channel: 0)?.value,
            let cameraState = session.cameraState(channel: 0)?.value,
            let focusRingValue = cameraState.focusRingValue,
            let focusRingMax = cameraState.focusRingMax,
            focusRingMax > 0
        else {
            detailsLabel.text = "CameraFocusCalibrationWidget.camera.unavailable".localized
            return
        }
        
        switch typeSegmentedControl.selectedSegmentIndex {
        //distance
        case 0:
            guard
                let location = session.state?.value.location,
                let heading = session.state?.value.orientation.yaw
            else {
                detailsLabel.text = "CameraFocusCalibrationWidget.location.unavailable".localized
                return
            }
            
            markReferenceButton.isEnabled = true
            
            guard let referenceLocation = referenceLocation else {
                detailsLabel.text = "CameraFocusCalibrationWidget.details.mark.reference".localized
                return
            }
            
            let distance = location.distance(from: referenceLocation)
            let referenceValid =
                abs(calibration.distance - distance) < 1 &&
                abs(gimbalState.orientation.pitch) < 1.convertDegreesToRadians &&
                abs(heading.angleDifferenceSigned(angle: location.coordinate.bearing(to: referenceLocation.coordinate))) < 15.convertDegreesToRadians
            referenceLabel.text = [Dronelink.shared.format(formatter: "distance", value: distance, defaultValue: ""), Dronelink.shared.format(formatter: "angle", value: gimbalState.orientation.pitch, extraParams: [false])].joined(separator: " | ")
            referenceLabel.backgroundColor = referenceValid ? referenceValidColor : referenceInvalidColor
            
            if !referenceValid {
                detailsLabel.text = String(format: "CameraFocusCalibrationWidget.details.move.distance".localized, Dronelink.shared.format(formatter: "distance", value: calibration.distance, defaultValue: ""))
                return
            }
            
            detailsLabel.text = String(format: (cameraState.isBusy ? "CameraFocusCalibrationWidget.details.busy" : "CameraFocusCalibrationWidget.details.focus.distance").localized, cameraFocusRingValues.count > 0 ? "\(cameraFocusRingValues.count)" : "--")
            break
            
        //altitude
        case 1:
            guard
                let takeoffLocation = session.state?.value.takeoffLocation,
                let location = session.state?.value.location,
                let altitude = session.state?.value.altitude
            else {
                detailsLabel.text = "CameraFocusCalibrationWidget.location.unavailable".localized
                return
            }
            
            let distance = location.distance(from: takeoffLocation)
            let referenceValid = distance < 2 && abs(calibration.distance - altitude) < 1 && abs(gimbalState.orientation.pitch - -90.convertDegreesToRadians) < 1.convertDegreesToRadians
            referenceLabel.text = [
                "\("DistanceWidget.prefix".localized) \(Dronelink.shared.format(formatter: "distance", value: distance, defaultValue: ""))",
                "\("AltitudeWidget.prefix".localized) \(Dronelink.shared.format(formatter: "altitude", value: altitude, defaultValue: ""))",
                Dronelink.shared.format(formatter: "angle", value: gimbalState.orientation.pitch, extraParams: [false])
            ].joined(separator: " | ")
            
            referenceLabel.backgroundColor = referenceValid ? referenceValidColor : referenceInvalidColor
            
            if !referenceValid {
                detailsLabel.text = String(format: "CameraFocusCalibrationWidget.details.move.altitude".localized, Dronelink.shared.format(formatter: "altitude", value: calibration.distance, defaultValue: ""))
                return
            }
            
            detailsLabel.text = String(format: (cameraState.isBusy ? "CameraFocusCalibrationWidget.details.busy" : "CameraFocusCalibrationWidget.details.focus.altitude").localized, cameraFocusRingValues.count > 0 ? "\(cameraFocusRingValues.count)" : "--")
            break
            
        default:
            break
        }
    
        if cameraState.isBusy {
            previousCameraBusyFocused = previousCameraBusyFocused || previousCameraFocusRingValue != focusRingValue
        }
        else {
            if previousCameraBusyFocused {
                cameraFocusRingValues.append(focusRingValue)
                cameraFocusRingValues.sort()
                let median = cameraFocusRingValues[Int((Double(cameraFocusRingValues.count) / 2.0) - 0.5)] / focusRingMax
                let cameraFocusRingValuesInRange = cameraFocusRingValues.filter { value in
                    return abs(median - (value / focusRingMax)) <= calibration.ringValueRange
                }
                
                if cameraFocusRingValuesInRange.count >= calibration.minRingValues {
                    let ringValue = cameraFocusRingValuesInRange[Int((Double(cameraFocusRingValuesInRange.count) / 2.0) - 0.5)]
                    calibration.ringValue = ringValue
                    calibration.droneSerialNumber = serialNumber
                    Dronelink.shared.update(cameraFocusCalibration: calibration)
                    DronelinkUI.shared.showSnackbar(text: String(format: "CameraFocusCalibrationWidget.finished".localized, "\(Int(ringValue))"))
                }
            }
            previousCameraFocusRingValue = focusRingValue
            previousCameraBusyFocused = false
        }
    }
}
