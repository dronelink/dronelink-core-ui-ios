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
    public var itemPadding = 2
    
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
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.addSubview(cameraIsoWidget.view)
        cameraIsoWidget.view.snp.makeConstraints { [weak self] make in
            make.top.equalToSuperview().offset(itemPadding)
            make.bottom.equalToSuperview().offset(-itemPadding)
            make.left.equalToSuperview().offset(itemPadding)
        }
        
        view.addSubview(cameraShutterWidget.view)
        cameraShutterWidget.view.snp.makeConstraints { [weak self] make in
            make.top.equalToSuperview().offset(itemPadding)
            make.bottom.equalToSuperview().offset(-itemPadding)
            make.left.equalTo(cameraIsoWidget.view.snp.right).offset(itemSpacing)
        }
        
        view.addSubview(cameraApertureWidget.view)
        cameraApertureWidget.view.snp.makeConstraints { [weak self] make in
            make.top.equalToSuperview().offset(itemPadding)
            make.bottom.equalToSuperview().offset(-itemPadding)
            make.left.equalTo(cameraShutterWidget.view.snp.right).offset(itemSpacing)
        }
        
        view.addSubview(cameraExposureCompensationWidget.view)
        cameraExposureCompensationWidget.view.snp.makeConstraints { [weak self] make in
            make.top.equalToSuperview().offset(itemPadding)
            make.bottom.equalToSuperview().offset(-itemPadding)
            make.left.equalTo(cameraApertureWidget.view.snp.right).offset(itemSpacing)
        }
        
        view.addSubview(cameraWhiteBalanceWidget.view)
        cameraWhiteBalanceWidget.view.snp.makeConstraints { [weak self] make in
            make.top.equalToSuperview().offset(itemPadding)
            make.bottom.equalToSuperview().offset(-itemPadding)
            make.left.equalTo(cameraExposureCompensationWidget.view.snp.right).offset(itemSpacing)
            make.right.equalToSuperview().offset(-itemPadding)
        }
    }
}
