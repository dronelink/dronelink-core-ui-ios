//
//  SignalWidget.swift
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

public class SignalWidget: UpdatableWidget {
    
    public let signal_0_Image = DronelinkUI.loadImage(named: "signal0")?.withRenderingMode(.alwaysOriginal)
    public let signal_1_Image = DronelinkUI.loadImage(named: "signal1")?.withRenderingMode(.alwaysOriginal)
    public let signal_2_Image = DronelinkUI.loadImage(named: "signal2")?.withRenderingMode(.alwaysOriginal)
    public let signal_3_Image = DronelinkUI.loadImage(named: "signal3")?.withRenderingMode(.alwaysOriginal)
    public let signal_4_Image = DronelinkUI.loadImage(named: "signal4")?.withRenderingMode(.alwaysOriginal)
    public let signal_5_Image = DronelinkUI.loadImage(named: "signal5")?.withRenderingMode(.alwaysOriginal)
    
    public let iconImageView = UIImageView(image: DronelinkUI.loadImage(named: "upLinkIcon")?.withRenderingMode(.alwaysOriginal))
    public let signalLevelImageView = UIImageView(image: DronelinkUI.loadImage(named: "signal0")?.withRenderingMode(.alwaysOriginal))
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalTo(self.view.snp.height)
            make.bottom.equalToSuperview()
        }
        
        view.addSubview(signalLevelImageView)
        signalLevelImageView.snp.makeConstraints { make in
            make.left.equalTo(iconImageView.snp.right).offset(5)
            make.top.equalToSuperview()
            make.width.equalTo(self.view.snp.height)
            make.bottom.equalToSuperview()
        }
    }
    
    func updateSignal(signalValue: Double) {
        if signalValue <= 0 {
            signalLevelImageView.image = signal_0_Image
        } else if signalValue <= 0.2 {
            signalLevelImageView.image = signal_1_Image
        } else if signalValue <= 0.4 {
            signalLevelImageView.image = signal_2_Image
        } else if signalValue <= 0.6 {
            signalLevelImageView.image = signal_3_Image
        } else if signalValue <= 0.8 {
            signalLevelImageView.image = signal_4_Image
        } else {
            signalLevelImageView.image = signal_5_Image
        }
    }
}
