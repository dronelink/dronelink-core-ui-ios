//
//  DownlinkWidget.swift
//  DronelinkCoreUI
//
//  Created by Nicolas Torres on 9/12/20.
//  Copyright © 2020 Dronelink. All rights reserved.
//

import Foundation
import UIKit
import DronelinkCore

public class DownlinkWidget: SignalWidget {
    
    public var channel: UInt = 0
    
    public var levelLabel: UILabel?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        iconImageView.image = DronelinkUI.loadImage(named: "downLinkIcon")?.withRenderingMode(.alwaysTemplate)
        iconImageView.tintColor = .white
        if let levelLabel = levelLabel {
            view.addSubview(levelLabel)
            levelLabel.textColor = .white
            levelLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
            levelImageView.isHidden = true
            levelLabel.snp.makeConstraints { [weak self] make in
                make.left.equalTo(iconImageView.snp.right).offset(5)
                make.top.equalToSuperview()
                make.width.equalTo(view.snp.height)
                make.bottom.equalToSuperview()
            }
        }
    }
    
    @objc public override func update() {
        super.update()
        
        if let levelLabel = levelLabel {
            guard let batteryPercent = session?.remoteControllerState(channel: self.channel)?.value.batteryPercent else {
                levelLabel.text = "na".localized
                return
            }
            levelLabel.text = Dronelink.shared.format(formatter: "percent", value: batteryPercent)
            return
        }
        
        updateSignal(signalValue: session?.state?.value.downlinkSignalStrength ?? 0)
    }
}
