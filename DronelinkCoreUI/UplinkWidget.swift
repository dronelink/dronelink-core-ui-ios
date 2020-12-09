//
//  UplinkWidget.swift
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

public class UplinkWidget: UpdatableWidget {
    
    public var iconImageView: UIImageView?
    public var signalLevelImageView: UIImageView?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        iconImageView = UIImageView(image: DronelinkUI.loadImage(named: "upLinkIcon")?.withRenderingMode(.alwaysOriginal))
        view.addSubview(iconImageView!)
        iconImageView?.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalTo(self.view.snp.height)
            make.bottom.equalToSuperview()
        }
        
        signalLevelImageView = UIImageView(image: DronelinkUI.loadImage(named: "gpsSignal0")?.withRenderingMode(.alwaysOriginal))
        view.addSubview(signalLevelImageView!)
        signalLevelImageView?.snp.makeConstraints { make in
            make.left.equalTo((iconImageView?.bounds.size.width ?? 0) + 5)
            make.top.equalToSuperview()
            make.width.equalTo(self.view.snp.height)
            make.bottom.equalToSuperview()
        }
    }
    
    private func updateSignal(signalValue: Double) {
        
        var imageName = ""
        
        if signalValue <= 0 {
            imageName = "gpsSignal0"
        } else if signalValue <= 0.2 {
            imageName = "gpsSignal1"
        } else if signalValue <= 0.4 {
            imageName = "gpsSignal2"
        } else if signalValue <= 0.6 {
            imageName = "gpsSignal3"
        } else if signalValue <= 0.8 {
            imageName = "gpsSignal4"
        } else {
            imageName = "gpsSignal5"
        }
        
        signalLevelImageView?.image = DronelinkUI.loadImage(named: imageName)?.withRenderingMode(.alwaysOriginal)
        
    }
    
    @objc public override func update() {
        super.update()
        updateSignal(signalValue: session?.state?.value.uplinkSignalStrength ?? 0)
    }
}
