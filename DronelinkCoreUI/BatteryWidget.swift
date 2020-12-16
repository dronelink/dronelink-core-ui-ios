//
//  BatteryWidget.swift
//  DronelinkCoreUI
//
//  Created by Nicolas Torres on 9/12/20.
//  Copyright © 2020 Dronelink. All rights reserved.
//

import Foundation
import UIKit
import DronelinkCore
import MaterialComponents.MaterialPalettes
import MaterialComponents.MaterialButtons
import MaterialComponents.MaterialButtons_Theming
import MarqueeLabel
import SnapKit

public class BatteryWidget: UpdatableWidget {
    public let imageView = UIImageView()
    public let label = UILabel()
    public var normalColor = MDCPalette.green.accent400!
    public var lowColor = MDCPalette.red.accent400!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.addShadow()
        imageView.image = DronelinkUI.loadImage(named: "batteryIcon")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .white
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalTo(view.snp.height)
            make.bottom.equalToSuperview()
        }
        
        label.addShadow()
        label.minimumScaleFactor = 0.5
        label.adjustsFontSizeToFitWidth = true
        label.textColor = .green
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.equalTo(imageView.snp.right)
            make.top.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    @objc public override func update() {
        super.update()
        
        guard let batteryPercent = session?.state?.value.batteryPercent else {
            label.text = "na".localized
            label.textColor = .white
            return
        }
        
        label.text = Dronelink.shared.format(formatter: "percent", value: batteryPercent)
        label.textColor = batteryPercent < (session?.state?.value.lowBatteryThreshold ?? 0) ? lowColor : normalColor
    }
}
