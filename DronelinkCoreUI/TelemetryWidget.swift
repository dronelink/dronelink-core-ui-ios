//
//  TelemetryWidget.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 11/21/19.
//  Copyright © 2019 Dronelink. All rights reserved.
//
import Foundation
import UIKit
import DronelinkCore
import SnapKit

public class TelemetryWidget: UpdatableWidget {
    public override var updateInterval: TimeInterval { 0.5 }
    
    private let distanceLabel = UILabel()
    private let altitudeLabel = UILabel()
    private let horizontalSpeedLabel = UILabel()
    private let verticalSpeedLabel = UILabel()
    
    private let distancePrefix = "TelemetryWidget.distance.prefix".localized
    private let distanceSuffixMetric = "TelemetryWidget.unit.distance.metric".localized
    private let distanceSuffixImperial = "TelemetryWidget.unit.distance.imperial".localized
    private let altitudePrefix = "TelemetryWidget.altitude.prefix".localized
    private let altitudeSuffixMetric = "TelemetryWidget.unit.distance.metric".localized
    private let altitudeSuffixImperial = "TelemetryWidget.unit.distance.imperial".localized
    private let horizontalSpeedPrefix = "TelemetryWidget.horizontalSpeed.prefix".localized
    private let horizontalSpeedSuffixMetric = "TelemetryWidget.unit.horizontalSpeed.metric".localized
    private let horizontalSpeedSuffixImperial = "TelemetryWidget.unit.horizontalSpeed.imperial".localized
    private let verticalSpeedPrefix = "TelemetryWidget.verticalSpeed.prefix".localized
    private let verticalSpeedSuffixMetric = "TelemetryWidget.unit.verticalSpeed.metric".localized
    private let verticalSpeedSuffixImperial = "TelemetryWidget.unit.verticalSpeed.imperial".localized
    
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
        
        distanceLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(defaultPadding)
            make.left.equalToSuperview().offset(defaultPadding)
            make.width.equalToSuperview().multipliedBy(0.45)
            make.height.equalTo(tablet ? 30 : 25)
        }
        
        altitudeLabel.snp.makeConstraints { make in
            make.top.equalTo(distanceLabel.snp.top)
            make.right.equalToSuperview().offset(-defaultPadding)
            make.width.equalTo(distanceLabel.snp.width)
            make.height.equalTo(distanceLabel.snp.height)
        }
        
        horizontalSpeedLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-defaultPadding)
            make.left.equalTo(distanceLabel.snp.left)
            make.width.equalTo(distanceLabel.snp.width)
            make.height.equalTo(distanceLabel.snp.height)
        }
        
        verticalSpeedLabel.snp.makeConstraints { make in
            make.bottom.equalTo(horizontalSpeedLabel.snp.bottom)
            make.right.equalTo(altitudeLabel.snp.right)
            make.width.equalTo(horizontalSpeedLabel.snp.width)
            make.height.equalTo(horizontalSpeedLabel.snp.height)
        }
    }
    
    @objc open override func update() {
        super.update()
        
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
}
