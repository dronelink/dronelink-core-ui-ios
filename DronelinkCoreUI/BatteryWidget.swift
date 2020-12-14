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
            make.width.equalTo(self.view.snp.height)
            make.bottom.equalToSuperview()
        }
        
        batteryLevelLabel.textColor = .green
        batteryLevelLabel.textAlignment = .left
        batteryLevelLabel.font = UIFont.systemFont(ofSize: 14)
        view.addSubview(batteryLevelLabel)
        batteryLevelLabel.snp.makeConstraints { make in
            make.left.equalTo(iconImageView.snp.right)
            make.top.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    private func updateBatteryLevel(batteryPercent: Double?) {
        guard let batteryValue = batteryPercent else {
            batteryLevelLabel.text = "N/A".localized
            batteryLevelLabel.textColor = .red
            return
        }
        
        batteryLevelLabel.text = String(format: "%.0f", batteryValue * 100) + "%"
        
        batteryLevelLabel.textColor = (session?.isLowerThanBatteryWarningThreshold ?? false) ? .red : .green
    }
    
    @objc public override func update() {
        super.update()
        updateBatteryLevel(batteryPercent: session?.state?.value.batteryPercent)
    }
}
