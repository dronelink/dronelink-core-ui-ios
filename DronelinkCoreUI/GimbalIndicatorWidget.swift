//
//  GimbalIndicatorWidget.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 6/11/21.
//  Copyright © 2021 Dronelink. All rights reserved.
//
import Foundation
import DronelinkCore

open class GimbalOrientationWidget: GimbalWidget {
    public override var updateInterval: TimeInterval { 0.1 }
    
    private let indicatorWidget = IndicatorWidget()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        indicatorWidget.setup(parent: view, title: "GimbalOrientationWidget.title".localized) { [weak self] in
            guard let orientation = self?.state?.orientation else {
                return "na".localized
            }
            
            return Dronelink.shared.format(formatter: "angle", value: orientation.pitch, extraParams: [false])
        }
    }
}
