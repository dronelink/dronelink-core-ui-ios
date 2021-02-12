//
//  CameraIndicatorWidget.swift
//  DronelinkCoreUI
//
//  Created by santiago on 9/2/21.
//  Copyright © 2021 Dronelink. All rights reserved.
//

import Foundation
import UIKit
import DronelinkCore
import SnapKit

open class CameraIndicatorWidget: UpdatableWidget {
    public let titleLabel = UILabel()
    public let valueLabel = UILabel()
    public var valueGenerator: (() -> String?)?
    public var channel: UInt = 0
    public var cameraState: CameraStateAdapter? { session?.cameraState(channel: channel)?.value }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        titleLabel.textColor = .white
        titleLabel.alpha = 0.6
        titleLabel.textAlignment = .left
        titleLabel.font = UIFont.systemFont(ofSize: 7.4, weight: .regular)
        titleLabel.adjustsFontSizeToFitWidth = true
        
        valueLabel.textColor = .white
        valueLabel.textAlignment = .left
        valueLabel.font = UIFont.systemFont(ofSize: 13.8, weight: .bold)
        valueLabel.adjustsFontSizeToFitWidth = true
        
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.right.equalToSuperview()
        }
        
        view.addSubview(valueLabel)
        valueLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom)
        }
    }
    
    @objc open override func update() {
        super.update()
        valueLabel.text = valueGenerator?() ?? ""
    }
}

open class CameraISOWidget: CameraIndicatorWidget {
    public override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = "CameraExposureWidget.iso.title".localized
        valueGenerator = {
            guard let iso = self.cameraState?.iso else {
                return "na".localized
            }
            
            return Dronelink.shared.formatEnum(name: "CameraISO",
                                               value: iso.rawValue,
                                               defaultValue: "na".localized)
        }
    }
}

open class CameraShutterWidget: CameraIndicatorWidget {
    public override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = "CameraExposureWidget.shutter.title".localized
        valueGenerator = {
            guard let shutter = self.cameraState?.shutterSpeed else {
                return "na".localized
            }
            
            return Dronelink.shared.formatEnum(name: "CameraShutterSpeed",
                                               value: shutter.rawValue,
                                               defaultValue: "na".localized)
        }
    }
}

open class CameraApertureWidget: CameraIndicatorWidget {
    public override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = "CameraExposureWidget.fstop.title".localized
        valueGenerator = {
            guard let aperture = self.cameraState?.aperture else {
                return "na".localized
            }
            
            return Dronelink.shared.formatEnum(name: "CameraAperture",
                                               value: aperture.rawValue,
                                               defaultValue: "na".localized)
        }
    }
}

open class CameraExposureCompensationWidget: CameraIndicatorWidget {
    public override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = "CameraExposureWidget.ev.title".localized
        valueGenerator = {
            guard let ev = self.cameraState?.exposureCompensation else {
                return "na".localized
            }
            
            return Dronelink.shared.formatEnum(name: "CameraExposureCompensation",
                                               value: ev.rawValue,
                                               defaultValue: "na".localized)
        }
    }
}

open class CameraWhiteBalanceWidget: CameraIndicatorWidget {
    public override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = "CameraExposureWidget.wb.title".localized
        valueGenerator = {
            guard let wb = self.cameraState?.whiteBalancePreset else {
                return "na".localized
            }
            
            if wb == .custom, let whiteBalanceValue = self.cameraState?.whiteBalanceCustom {
                return Dronelink.shared.format(formatter: "absoluteTemperature",
                                               value: whiteBalanceValue,
                                               defaultValue: "na".localized)
            }
            return Dronelink.shared.formatEnum(name: "CameraWhiteBalancePreset",
                                               value: wb.rawValue,
                                               defaultValue: "na".localized)
        }
    }
}

