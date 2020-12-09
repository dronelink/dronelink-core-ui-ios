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

public class TelemetryWidget: Widget {
    private let distanceWidget = WidgetFactory.shared.createDistanceWidget()
    private let altitudeWidget = WidgetFactory.shared.createAltitudeWidget()
    private let horizontalSpeedWidget = WidgetFactory.shared.createHorizontalSpeedWidget()
    private let verticalSpeedWidget = WidgetFactory.shared.createVerticalSpeedWidget()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addShadow()
        view.layer.cornerRadius = DronelinkUI.Constants.cornerRadius
        view.backgroundColor = DronelinkUI.Constants.overlayColor
        
        guard
            let distanceWidget = distanceWidget,
            let altitudeWidget = altitudeWidget,
            let horizontalSpeedWidget = horizontalSpeedWidget,
            let verticalSpeedWidget = verticalSpeedWidget
        else {
            return
        }
        
        view.addSubview(distanceWidget.view)
        distanceWidget.view.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(defaultPadding)
            make.left.equalToSuperview().offset(defaultPadding)
            make.width.equalToSuperview().multipliedBy(0.45)
            make.height.equalTo(tablet ? 30 : 25)
        }

        view.addSubview(altitudeWidget.view)
        altitudeWidget.view.snp.makeConstraints { make in
            make.top.equalTo(distanceWidget.view.snp.top)
            make.right.equalToSuperview().offset(-defaultPadding)
            make.width.equalTo(distanceWidget.view.snp.width)
            make.height.equalTo(distanceWidget.view.snp.height)
        }
        
        view.addSubview(horizontalSpeedWidget.view)
        horizontalSpeedWidget.view.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-defaultPadding)
            make.left.equalTo(distanceWidget.view.snp.left)
            make.width.equalTo(distanceWidget.view.snp.width)
            make.height.equalTo(distanceWidget.view.snp.height)
        }
            
        view.addSubview(verticalSpeedWidget.view)
        verticalSpeedWidget.view.snp.makeConstraints { make in
            make.bottom.equalTo(horizontalSpeedWidget.view.snp.bottom)
            make.right.equalTo(altitudeWidget.view.snp.right)
            make.width.equalTo(horizontalSpeedWidget.view.snp.width)
            make.height.equalTo(horizontalSpeedWidget.view.snp.height)
        }
    }
}
