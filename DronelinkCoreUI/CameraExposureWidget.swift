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
    private let isoWidget = WidgetFactory.shared.createISOWidget()
    private let shutterWidget = WidgetFactory.shared.createShutterWidget()
    private let fStopWidget = WidgetFactory.shared.createFStopWidget()
    private let evWidget = WidgetFactory.shared.createEVWidget()
    private let wbWidget = WidgetFactory.shared.createWBWidget()
    public var itemSpacing = 8
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        guard
            let isoWidget = isoWidget,
            let shutterWidget = shutterWidget,
            let fStopWidget = fStopWidget,
            let evWidget = evWidget,
            let wbWidget = wbWidget
        else {
            return
        }
        
        view.addSubview(isoWidget.view)
        isoWidget.view.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(itemSpacing)
        }
        
        view.addSubview(shutterWidget.view)
        shutterWidget.view.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalTo(isoWidget.view.snp.right).offset(itemSpacing)
        }
        
        view.addSubview(fStopWidget.view)
        fStopWidget.view.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalTo(shutterWidget.view.snp.right).offset(itemSpacing)
        }
        
        view.addSubview(evWidget.view)
        evWidget.view.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalTo(fStopWidget.view.snp.right).offset(itemSpacing)
        }
        
        view.addSubview(wbWidget.view)
        wbWidget.view.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalTo(evWidget.view.snp.right).offset(itemSpacing)
            make.right.equalToSuperview()
        }
       
    }

}
