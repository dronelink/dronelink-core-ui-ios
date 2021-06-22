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

open class CameraIndicatorWidget: IndicatorWidget {
    public var channel: UInt = 0
    public var cameraState: CameraStateAdapter? { session?.cameraState(channel: channel)?.value }
}

open class CameraFocusRingWidget: CameraIndicatorWidget {
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        titleLabel.text = "CameraIndicatorWidget.focusring.title".localized
        valueGenerator = { [weak self] in
            guard
                let focusRingValue = self?.cameraState?.focusRingValue,
                let focusRingMax = self?.cameraState?.focusRingMax
            else {
                return "na".localized
            }
            
            return "\(Int(focusRingValue))/\(Int(focusRingMax))"
        }
    }
}

open class CameraISOWidget: CameraIndicatorWidget {
    public override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = "CameraExposureWidget.iso.title".localized
        valueGenerator = { [weak self] in
            guard let iso = self?.cameraState?.iso else {
                return "na".localized
            }
            
            if iso == .auto, let isoSensitivity = self?.cameraState?.isoSensitivity {
                return "\(isoSensitivity)"
            }
            return Dronelink.shared.formatEnum(name: "CameraISO",
                                               value: iso.rawValue,
                                               defaultValue: "na".localized)
        }
    }
    
    open override func update() {
        super.update()
        guard let iso = cameraState?.iso else { return }
        if iso == .auto {
            titleLabel.text = "CameraExposureWidget.autoiso.title".localized
        } else {
            titleLabel.text = "CameraExposureWidget.iso.title".localized
        }
    }
}

open class CameraShutterWidget: CameraIndicatorWidget {
    public override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = "CameraExposureWidget.shutter.title".localized
        valueGenerator = { [weak self] in
            guard let shutter = self?.cameraState?.shutterSpeed else {
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
        valueGenerator = { [weak self] in
            guard let aperture = self?.cameraState?.aperture else {
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
        valueGenerator = { [weak self] in
            guard let ev = self?.cameraState?.exposureCompensation else {
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
        valueGenerator = { [weak self] in
            guard let wb = self?.cameraState?.whiteBalancePreset else {
                return "na".localized
            }
            
            if wb == .custom, let whiteBalanceColorTemperature = self?.cameraState?.whiteBalanceColorTemperature {
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
