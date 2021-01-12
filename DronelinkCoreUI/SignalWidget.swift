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

public class SignalWidget: UpdatableWidget {
    public let iconImageView = UIImageView()
    public let levelImageView = UIImageView()
    
    public var level0Image = DronelinkUI.loadImage(named: "signal0")?.withRenderingMode(.alwaysOriginal)
    public var level1Image = DronelinkUI.loadImage(named: "signal1")?.withRenderingMode(.alwaysOriginal)
    public var level2Image = DronelinkUI.loadImage(named: "signal2")?.withRenderingMode(.alwaysOriginal)
    public var level3Image = DronelinkUI.loadImage(named: "signal3")?.withRenderingMode(.alwaysOriginal)
    public var level4Image = DronelinkUI.loadImage(named: "signal4")?.withRenderingMode(.alwaysOriginal)
    public var level5Image = DronelinkUI.loadImage(named: "signal5")?.withRenderingMode(.alwaysOriginal)
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        iconImageView.addShadow()
        iconImageView.image = DronelinkUI.loadImage(named: "upLinkIcon")?.withRenderingMode(.alwaysOriginal)
        view.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalTo(self.view.snp.height)
            make.bottom.equalToSuperview()
        }
        
        levelImageView.addShadow()
        levelImageView.image = level0Image
        view.addSubview(levelImageView)
        levelImageView.snp.makeConstraints { make in
            make.left.equalTo(iconImageView.snp.right).offset(5)
            make.top.equalToSuperview()
            make.width.equalTo(self.view.snp.height)
            make.bottom.equalToSuperview()
        }
    }
    
    func updateSignal(signalValue: Double) {
        if signalValue <= 0 {
            levelImageView.image = level0Image
        } else if signalValue <= 0.2 {
            levelImageView.image = level1Image
        } else if signalValue <= 0.4 {
            levelImageView.image = level2Image
        } else if signalValue <= 0.6 {
            levelImageView.image = level3Image
        } else if signalValue <= 0.8 {
            levelImageView.image = level4Image
        } else {
            levelImageView.image = level5Image
        }
    }
}
