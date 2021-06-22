//
//  GimbalIndicatorWidget.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 6/11/21.
//  Copyright © 2021 Dronelink. All rights reserved.
//
import Foundation
import DronelinkCore

open class GimbalIndicatorWidget: IndicatorWidget {
    public var channel: UInt = 0
    public var gimbalState: GimbalStateAdapter? { session?.gimbalState(channel: channel)?.value }
}

open class GimbalOrientationWidget: GimbalIndicatorWidget {
    public override var updateInterval: TimeInterval { 0.1 }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = "GimbalOrientationWidget.title".localized
        valueGenerator = { [weak self] in
            guard let orientation = self?.gimbalState?.orientation else {
                return "na".localized
            }
            
            return Dronelink.shared.format(formatter: "angle", value: orientation.pitch, extraParams: [false])
        }
    }
}
