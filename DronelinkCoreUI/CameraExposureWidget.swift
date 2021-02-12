//
//  CameraExposureWidget.swift
//  DronelinkCoreUI
//
//  Created by santiago on 8/2/21.
//  Copyright © 2021 Dronelink. All rights reserved.
//

import Foundation
import UIKit
import DronelinkCore
import SnapKit
    
public class CameraExposureWidget: Widget {
    private let cameraIsoWidget = WidgetFactory.shared.createCameraISOWidget()
    private let cameraShutterWidget = WidgetFactory.shared.createCameraShutterWidget()
    private let cameraApertureWidget = WidgetFactory.shared.createCameraApertureWidget()
    private let cameraExposureCompensationWidget = WidgetFactory.shared.createCameraExposureCompensationWidget()
    private let cameraWhiteBalanceWidget = WidgetFactory.shared.createCameraWhiteBalanceWidget()
    public var itemSpacing = 8
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        guard
            let cameraIsoWidget = cameraIsoWidget,
            let cameraShutterWidget = cameraShutterWidget,
            let cameraApertureWidget = cameraApertureWidget,
            let cameraExposureCompensationWidget = cameraExposureCompensationWidget,
            let cameraWhiteBalanceWidget = cameraWhiteBalanceWidget
        else {
            return
        }
        
        view.addSubview(cameraIsoWidget.view)
        cameraIsoWidget.view.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(itemSpacing)
        }
        
        view.addSubview(cameraShutterWidget.view)
        cameraShutterWidget.view.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalTo(cameraIsoWidget.view.snp.right).offset(itemSpacing)
        }
        
        view.addSubview(cameraApertureWidget.view)
        cameraApertureWidget.view.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalTo(cameraShutterWidget.view.snp.right).offset(itemSpacing)
        }
        
        view.addSubview(cameraExposureCompensationWidget.view)
        cameraExposureCompensationWidget.view.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalTo(cameraApertureWidget.view.snp.right).offset(itemSpacing)
        }
        
        view.addSubview(cameraWhiteBalanceWidget.view)
        cameraWhiteBalanceWidget.view.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalTo(cameraExposureCompensationWidget.view.snp.right).offset(itemSpacing)
            make.right.equalToSuperview()
        }
       
    }

}
