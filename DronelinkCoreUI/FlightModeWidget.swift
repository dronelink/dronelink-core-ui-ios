//
//  FlightModeWidget.swift
//  DronelinkCoreUI
//
//  Created by Nicolas Torres on 8/12/20.
//  Copyright © 2020 Dronelink. All rights reserved.
//

import Foundation
import UIKit
import DronelinkCore

public class FlightModeWidget: UpdatableWidget {
    public override var updateInterval: TimeInterval { 0.5 }
    
    public var imgageView = UIImageView()
    public var label = UILabel()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        imgageView.addShadow()
        imgageView.image = DronelinkUI.loadImage(named: "flightModeIcon")?.withRenderingMode(.alwaysOriginal)
        view.addSubview(imgageView)
        imgageView.snp.makeConstraints { [weak self] make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalTo(view.snp.height)
            make.bottom.equalToSuperview()
        }
        
        label.addShadow()
        label.numberOfLines = 1
        label.minimumScaleFactor = 0.5
        label.adjustsFontSizeToFitWidth = true
        label.textColor = .white
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        view.addSubview(label)
        label.snp.makeConstraints { [weak self] make in
            make.left.equalTo(imgageView.snp.right).offset(7)
            make.top.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    @objc public override func update() {
        super.update()
        label.text = String(session?.state?.value.mode ?? "na".localized)
    }
}
