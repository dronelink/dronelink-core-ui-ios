//
//  TelemetryViewController.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 11/21/19.
//  Copyright © 2019 Dronelink. All rights reserved.
//

import Foundation
import UIKit
import DronelinkCore
import SnapKit

public class TelemetryViewController: UIViewController {
    public static func create(droneSessionManager: DroneSessionManager) -> TelemetryViewController {
        let telemetryViewController = TelemetryViewController()
        telemetryViewController.droneSessionManager = droneSessionManager
        return telemetryViewController
    }
    
    private var droneSessionManager: DroneSessionManager!
    private var session: DroneSession?
    
    private let distanceLabel = UILabel()
    private let altitudeLabel = UILabel()
    private let horizontalSpeedLabel = UILabel()
    private let verticalSpeedLabel = UILabel()
    
    private let updateInterval: TimeInterval = 0.5
    private var updateTimer: Timer?
    
    private let distancePrefix = "TelemetryViewController.distance.prefix".localized
    private let distanceSuffixMetric = "TelemetryViewController.unit.distance.metric".localized
    private let distanceSuffixImperial = "TelemetryViewController.unit.distance.imperial".localized
    private let altitudePrefix = "TelemetryViewController.altitude.prefix".localized
    private let altitudeSuffixMetric = "TelemetryViewController.unit.distance.metric".localized
    private let altitudeSuffixImperial = "TelemetryViewController.unit.distance.imperial".localized
    private let horizontalSpeedPrefix = "TelemetryViewController.horizontalSpeed.prefix".localized
    private let horizontalSpeedSuffixMetric = "TelemetryViewController.unit.horizontalSpeed.metric".localized
    private let horizontalSpeedSuffixImperial = "TelemetryViewController.unit.horizontalSpeed.imperial".localized
    private let verticalSpeedPrefix = "TelemetryViewController.verticalSpeed.prefix".localized
    private let verticalSpeedSuffixMetric = "TelemetryViewController.unit.verticalSpeed.metric".localized
    private let verticalSpeedSuffixImperial = "TelemetryViewController.unit.verticalSpeed.imperial".localized
    
    private let defaultPadding = 10
    private var tablet: Bool { return UIDevice.current.userInterfaceIdiom == .pad }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addShadow()
        view.layer.cornerRadius = DronelinkUI.Constants.cornerRadius
        view.backgroundColor = DronelinkUI.Constants.overlayColor
        
        distanceLabel.textColor = UIColor.white
        distanceLabel.font = UIFont.systemFont(ofSize: tablet ? 32 : 24, weight: .semibold)
        altitudeLabel.textColor = distanceLabel.textColor
        altitudeLabel.font = distanceLabel.font
        horizontalSpeedLabel.textColor = distanceLabel.textColor
        horizontalSpeedLabel.font = UIFont.systemFont(ofSize: tablet ? 22 : 16, weight: .semibold)
        verticalSpeedLabel.textColor = distanceLabel.textColor
        verticalSpeedLabel.font = horizontalSpeedLabel.font
        
        view.addSubview(distanceLabel)
        view.addSubview(altitudeLabel)
        view.addSubview(horizontalSpeedLabel)
        view.addSubview(verticalSpeedLabel)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateTimer = Timer.scheduledTimer(timeInterval: updateInterval, target: self, selector: #selector(update), userInfo: nil, repeats: true)
        droneSessionManager.add(delegate: self)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        updateTimer?.invalidate()
        updateTimer = nil
        droneSessionManager.remove(delegate: self)
    }
    
    public override func updateViewConstraints() {
        super.updateViewConstraints()
        updateConstraints()
    }
    
    @objc func update() {
        var distance = 0.0
        var altitude = 0.0
        var horizontalSpeed = 0.0
        var verticalSpeed = 0.0
        if let state = session?.state?.value {
            if let droneLocation = state.location {
                if let userLocation = Dronelink.shared.location?.value {
                    distance = userLocation.distance(from: droneLocation)
                }
                else if let homeLocation = state.homeLocation {
                    distance = homeLocation.distance(from: droneLocation)
                }
                
                if (distance > 10000) {
                    distance = 0
                }
            }
            
            altitude = state.altitude
            horizontalSpeed = state.horizontalSpeed
            verticalSpeed = state.verticalSpeed
        }
        
        switch Dronelink.shared.unitSystem {
        case .imperial:
            distance = distance.convertMetersToFeet
            altitude = altitude.convertMetersToFeet
            horizontalSpeed = horizontalSpeed.convertMetersPerSecondToMilesPerHour
            verticalSpeed = verticalSpeed.convertMetersToFeet
            break
            
        case .metric:
            horizontalSpeed = horizontalSpeed.convertMetersPerSecondToKilometersPerHour
            break
        }
        
        distance = distance.rounded(toPlaces: distance > 10 ? 0 : 1)
        altitude = altitude.rounded(toPlaces: altitude > 10 ? 0 : 1)
        horizontalSpeed = horizontalSpeed.rounded(toPlaces: horizontalSpeed > 10 ? 0 : 1)
        verticalSpeed = verticalSpeed.rounded(toPlaces: verticalSpeed > 10 ? 0 : 1)
        
        distanceLabel.text = "\(distancePrefix) \(NumberFormatter.localizedString(from: distance as NSNumber, number: .decimal)) \(Dronelink.shared.unitSystem == .metric ? distanceSuffixMetric : distanceSuffixImperial)"
        altitudeLabel.text = "\(altitudePrefix) \(NumberFormatter.localizedString(from: altitude as NSNumber, number: .decimal)) \(Dronelink.shared.unitSystem == .metric ? altitudeSuffixMetric : altitudeSuffixImperial)"
        horizontalSpeedLabel.text = "\(horizontalSpeedPrefix) \(NumberFormatter.localizedString(from: horizontalSpeed as NSNumber, number: .decimal)) \(Dronelink.shared.unitSystem == .metric ? horizontalSpeedSuffixMetric : horizontalSpeedSuffixImperial)"
        verticalSpeedLabel.text = "\(verticalSpeedPrefix) \(NumberFormatter.localizedString(from: verticalSpeed as NSNumber, number: .decimal)) \(Dronelink.shared.unitSystem == .metric ? verticalSpeedSuffixMetric : verticalSpeedSuffixImperial)"
    }
    
    func updateConstraints() {
        distanceLabel.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(defaultPadding)
            make.left.equalToSuperview().offset(defaultPadding)
            make.width.equalToSuperview().multipliedBy(0.45)
            make.height.equalTo(tablet ? 30 : 25)
        }
        
        altitudeLabel.snp.remakeConstraints { make in
            make.top.equalTo(distanceLabel.snp.top)
            make.right.equalToSuperview().offset(-defaultPadding)
            make.width.equalTo(distanceLabel.snp.width)
            make.height.equalTo(distanceLabel.snp.height)
        }
        
        horizontalSpeedLabel.snp.remakeConstraints { make in
            make.bottom.equalToSuperview().offset(-defaultPadding)
            make.left.equalTo(distanceLabel.snp.left)
            make.width.equalTo(distanceLabel.snp.width)
            make.height.equalTo(distanceLabel.snp.height)
        }
        
        verticalSpeedLabel.snp.remakeConstraints { make in
            make.bottom.equalTo(horizontalSpeedLabel.snp.bottom)
            make.right.equalTo(altitudeLabel.snp.right)
            make.width.equalTo(horizontalSpeedLabel.snp.width)
            make.height.equalTo(horizontalSpeedLabel.snp.height)
        }
    }
}

extension TelemetryViewController: DroneSessionManagerDelegate {
    public func onOpened(session: DroneSession) {
        self.session = session
        DispatchQueue.main.async {
            self.view.setNeedsUpdateConstraints()
        }
    }
    
    public func onClosed(session: DroneSession) {
        self.session = nil
        DispatchQueue.main.async {
            self.view.setNeedsUpdateConstraints()
        }
    }
}
