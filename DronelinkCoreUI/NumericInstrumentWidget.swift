//
//  NumericInstrumentWidget.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 12/8/20.
//  Copyright © 2020 Dronelink. All rights reserved.
//
import UIKit
import DronelinkCore
import SnapKit

open class NumericInstrumentWidget: UpdatableWidget {
    public override var updateInterval: TimeInterval { 0.5 }
    
    public var prefixText: String?
    public let prefixLabel = UILabel()
    public let prefixIcon = UIImageView()
    public let valueLabel = UILabel()
    public var valueGenerator: (() -> String?)?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        prefixLabel.textColor = UIColor.white
        prefixLabel.font = UIFont.systemFont(ofSize: tablet ? 28 : 20, weight: .semibold)
        prefixLabel.textAlignment = .center
        view.addSubview(prefixLabel)
        prefixLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.width.equalTo(prefixLabel.snp.height).multipliedBy(1.25)
        }
        
        view.addSubview(prefixIcon)
        prefixIcon.snp.makeConstraints { make in
            make.edges.equalTo(prefixLabel)
        }
        
        valueLabel.textColor = UIColor.white
        valueLabel.font = UIFont.systemFont(ofSize: tablet ? 32 : 24, weight: .semibold)
        view.addSubview(valueLabel)
        valueLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalTo(prefixLabel.snp.right).offset(5)
            make.right.equalToSuperview()
        }
    }
    
    @objc open override func update() {
        super.update()
        
        if let prefixText = prefixText {
            prefixIcon.isHidden = true
            prefixLabel.isHidden = false
            prefixLabel.text = prefixText
        }
        else {
            prefixIcon.isHidden = false
            prefixLabel.isHidden = true
        }
        
        valueLabel.text = valueGenerator?() ?? ""
    }
}

open class AltitudeWidget: NumericInstrumentWidget {
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        prefixText = "AltitudeWidget.prefix".localized
        valueGenerator = {
            Dronelink.shared.format(formatter: "altitude", value: self.session?.state?.value.altitude, defaultValue: "NumericInstrumentWidget.empty".localized)
        }
    }
}

open class DistanceWidget: NumericInstrumentWidget {
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        prefixText = "DistanceWidget.prefix".localized
        valueGenerator = {
            var distance = 0.0
            if let state = self.session?.state?.value {
                if let droneLocation = state.location {
                    if let userLocation = Dronelink.shared.location?.value {
                        distance = userLocation.distance(from: droneLocation)
                    }
                    else if let homeLocation = state.homeLocation {
                        distance = homeLocation.distance(from: droneLocation)
                    }
                }
            }
            
            return Dronelink.shared.format(formatter: "distance", value: distance, defaultValue: "NumericInstrumentWidget.empty".localized)
        }
    }
}

open class DistanceHomeWidget: NumericInstrumentWidget {
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        prefixText = "DistanceWidget.prefix".localized
        valueGenerator = {
            var distance = 0.0
            if let state = self.session?.state?.value, let droneLocation = state.location {
                distance = state.homeLocation?.distance(from: droneLocation) ?? 0
            }
            
            return Dronelink.shared.format(formatter: "distance", value: distance, defaultValue: "NumericInstrumentWidget.empty".localized)
        }
    }
}

open class DistanceUserWidget: NumericInstrumentWidget {
    public override func viewDidLoad() {
        super.viewDidLoad()

        prefixText = "DistanceWidget.prefix".localized
        valueGenerator = {
            var distance = 0.0
            if let state = self.session?.state?.value, let droneLocation = state.location {
                distance = Dronelink.shared.location?.value.distance(from: droneLocation) ?? 0
            }
            
            return Dronelink.shared.format(formatter: "distance", value: distance, defaultValue: "NumericInstrumentWidget.empty".localized)
        }
    }
}

open class HorizontalSpeedWidget: NumericInstrumentWidget {
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        prefixText = "HorizontalSpeedWidget.prefix".localized
        prefixLabel.font = UIFont.systemFont(ofSize: tablet ? 22 : 16, weight: .semibold)
        valueLabel.font = UIFont.systemFont(ofSize: tablet ? 22 : 16, weight: .semibold)
        valueGenerator = {
            Dronelink.shared.format(formatter: "velocityHorizontal", value: self.session?.state?.value.horizontalSpeed, defaultValue: "NumericInstrumentWidget.empty".localized)
        }
    }
}

open class VerticalSpeedWidget: NumericInstrumentWidget {
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        prefixText = "VerticalSpeedWidget.prefix".localized
        prefixLabel.font = UIFont.systemFont(ofSize: tablet ? 22 : 16, weight: .semibold)
        valueLabel.font = UIFont.systemFont(ofSize: tablet ? 22 : 16, weight: .semibold)
        valueGenerator = {
            Dronelink.shared.format(formatter: "velocityVertical", value: self.session?.state?.value.verticalSpeed, defaultValue: "NumericInstrumentWidget.empty".localized)
        }
    }
}


