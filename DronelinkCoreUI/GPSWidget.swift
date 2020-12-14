//
//  GPSWidget.swift
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

public class GPSWidget: UpdatableWidget {
    
    public let gpsIconImageView = UIImageView(image: DronelinkUI.loadImage(named: "signalIcon")?.withRenderingMode(.alwaysOriginal))
    public let gpsSignalLevelLabel = UILabel()
    public let gpsSignalLevelImageView = UIImageView(image: DronelinkUI.loadImage(named: "signal0")?.withRenderingMode(.alwaysOriginal))
    
    public let signal_0_Image = DronelinkUI.loadImage(named: "signal0")?.withRenderingMode(.alwaysOriginal)
    public let signal_1_Image = DronelinkUI.loadImage(named: "signal1")?.withRenderingMode(.alwaysOriginal)
    public let signal_2_Image = DronelinkUI.loadImage(named: "signal2")?.withRenderingMode(.alwaysOriginal)
    public let signal_3_Image = DronelinkUI.loadImage(named: "signal3")?.withRenderingMode(.alwaysOriginal)
    public let signal_4_Image = DronelinkUI.loadImage(named: "signal4")?.withRenderingMode(.alwaysOriginal)
    public let signal_5_Image = DronelinkUI.loadImage(named: "signal5")?.withRenderingMode(.alwaysOriginal)
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(gpsIconImageView)
        gpsIconImageView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalTo(self.view.snp.height)
            make.bottom.equalToSuperview()
        }
        
        gpsSignalLevelLabel.textColor = .white
        gpsSignalLevelLabel.textAlignment = .left
        gpsSignalLevelLabel.font = UIFont.systemFont(ofSize: 10)
        view.addSubview(gpsSignalLevelLabel)
        gpsSignalLevelLabel.snp.makeConstraints { make in
            make.left.equalTo(gpsIconImageView.snp.right).offset(5)
            make.top.equalTo(0)
            make.bottom.equalToSuperview().offset(-10)
        }
        
        view.addSubview(gpsSignalLevelImageView)
        gpsSignalLevelImageView.snp.makeConstraints { make in
            make.left.equalTo(gpsIconImageView.snp.right).offset(5)
            make.top.equalToSuperview()
            make.width.equalTo(self.view.snp.height)
            make.bottom.equalToSuperview()
        }
    }
    
    private func updateGpsSignal(signalValue: Kernel.GPSSignalLevel) {
        
        gpsSignalLevelLabel.text = signalValue.rawValue
        gpsSignalLevelLabel.isHidden = signalValue == .none
        
        switch signalValue {
        case ._0:
            gpsSignalLevelImageView.image = signal_0_Image
        case ._1:
            gpsSignalLevelImageView.image = signal_1_Image
        case ._2:
            gpsSignalLevelImageView.image = signal_2_Image
        case ._3:
            gpsSignalLevelImageView.image = signal_3_Image
        case ._4:
            gpsSignalLevelImageView.image = signal_4_Image
        case ._5:
            gpsSignalLevelImageView.image = signal_5_Image
        case .none:
            gpsSignalLevelImageView.image = signal_0_Image
        }
    }
    
    @objc public override func update() {
        super.update()
        updateGpsSignal(signalValue: session?.state?.value.gpsSignalLevel ?? Kernel.GPSSignalLevel.none)
    }
}
