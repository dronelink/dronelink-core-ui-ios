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

open class CameraFocusRingWidget: CameraWidget {
    private let indicatorWidget = IndicatorWidget()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        indicatorWidget.setup(parent: view, title: "CameraIndicatorWidget.focusring.title".localized) { [weak self] in
            guard
                let focusRingValue = self?.state?.focusRingValue,
                let focusRingMax = self?.state?.focusRingMax
            else {
                return "na".localized
            }
            
            return "\(Int(focusRingValue))/\(Int(focusRingMax))"
        }
    }
}

open class CameraISOWidget: CameraWidget {
    private let indicatorWidget = IndicatorWidget()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        indicatorWidget.setup(parent: view, title: "CameraExposureWidget.iso.title".localized) { [weak self] in
            guard let iso = self?.state?.iso else {
                return "na".localized
            }
            
            if iso == .auto, let isoSensitivity = self?.state?.isoSensitivity {
                return "\(isoSensitivity)"
            }
            return Dronelink.shared.formatEnum(name: "CameraISO",
                                               value: iso.rawValue,
                                               defaultValue: "na".localized)
        }
    }
    
    open override func update() {
        super.update()
        guard let iso = state?.iso else { return }
        if iso == .auto {
            indicatorWidget.titleLabel.text = "CameraExposureWidget.autoiso.title".localized
        } else {
            indicatorWidget.titleLabel.text = "CameraExposureWidget.iso.title".localized
        }
    }
}

open class CameraShutterWidget: CameraWidget {
    private let indicatorWidget = IndicatorWidget()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        indicatorWidget.setup(parent: view, title: "CameraExposureWidget.shutter.title".localized) { [weak self] in
            guard let shutter = self?.state?.shutterSpeed else {
                return "na".localized
            }
            
            return Dronelink.shared.formatEnum(name: "CameraShutterSpeed",
                                               value: shutter.rawValue,
                                               defaultValue: "na".localized)
        }
    }
}

open class CameraApertureWidget: CameraWidget {
    private let indicatorWidget = IndicatorWidget()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        indicatorWidget.setup(parent: view, title: "CameraExposureWidget.fstop.title".localized) { [weak self] in
            guard let aperture = self?.state?.aperture else {
                return "na".localized
            }
            
            return Dronelink.shared.formatEnum(name: "CameraAperture",
                                               value: aperture.rawValue,
                                               defaultValue: "na".localized)
        }
    }
}

open class CameraExposureCompensationWidget: CameraWidget {
    private let indicatorWidget = IndicatorWidget()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        indicatorWidget.setup(parent: view, title: "CameraExposureWidget.ev.title".localized) { [weak self] in
            guard let ev = self?.state?.exposureCompensation else {
                return "na".localized
            }
            
            return Dronelink.shared.formatEnum(name: "CameraExposureCompensation",
                                               value: ev.rawValue,
                                               defaultValue: "na".localized)
        }
    }
}

open class CameraWhiteBalanceWidget: CameraWidget {
    private let indicatorWidget = IndicatorWidget()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        indicatorWidget.setup(parent: view, title: "CameraExposureWidget.wb.title".localized) { [weak self] in
            guard let wb = self?.state?.whiteBalancePreset else {
                return "na".localized
            }
            
            if wb == .custom, let whiteBalanceColorTemperature = self?.state?.whiteBalanceColorTemperature {
                return Dronelink.shared.format(formatter: "absoluteTemperature",
                                               value: whiteBalanceColorTemperature,
                                               defaultValue: "na".localized)
            }
            return Dronelink.shared.formatEnum(name: "CameraWhiteBalancePreset",
                                               value: wb.rawValue,
                                               defaultValue: "na".localized)
        }
    }
}
