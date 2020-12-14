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
    public let iconImageView = UIImageView(image: DronelinkUI.loadImage(named: "batteryIcon")?.withRenderingMode(.alwaysTemplate))
    public let batteryLevelLabel = UILabel()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        iconImageView.tintColor = .white
        view.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalTo(view.snp.height)
            make.bottom.equalToSuperview()
        }
        
        batteryLevelLabel.textColor = .green
        batteryLevelLabel.textAlignment = .left
        batteryLevelLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        view.addSubview(batteryLevelLabel)
        batteryLevelLabel.snp.makeConstraints { make in
            make.left.equalTo(iconImageView.snp.right)
            make.top.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    @objc public override func update() {
        super.update()
        
        guard let batteryPercent = session?.state?.value.batteryPercent else {
            batteryLevelLabel.text = "na".localized
            batteryLevelLabel.textColor = .white
            return
        }
        
        batteryLevelLabel.text = Dronelink.shared.format(formatter: "percent", value: batteryPercent)
        batteryLevelLabel.textColor = batteryPercent < (session?.state?.value.lowBatteryThreshold ?? 0) ? MDCPalette.red.accent400 : MDCPalette.green.accent400
    }
}
