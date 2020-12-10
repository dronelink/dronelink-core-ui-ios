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
    
    public var gpsIconImageView: UIImageView?
    public var gpsSignalLevelLabel: UILabel?
    public var gpsSignalLevelImageView: UIImageView?
    
    private let signal_0_Image = DronelinkUI.loadImage(named: "gpsSignal0")?.withRenderingMode(.alwaysOriginal)
    private let signal_1_Image = DronelinkUI.loadImage(named: "gpsSignal1")?.withRenderingMode(.alwaysOriginal)
    private let signal_2_Image = DronelinkUI.loadImage(named: "gpsSignal2")?.withRenderingMode(.alwaysOriginal)
    private let signal_3_Image = DronelinkUI.loadImage(named: "gpsSignal3")?.withRenderingMode(.alwaysOriginal)
    private let signal_4_Image = DronelinkUI.loadImage(named: "gpsSignal4")?.withRenderingMode(.alwaysOriginal)
    private let signal_5_Image = DronelinkUI.loadImage(named: "gpsSignal5")?.withRenderingMode(.alwaysOriginal)
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        gpsIconImageView = UIImageView(image: DronelinkUI.loadImage(named: "gpsIcon")?.withRenderingMode(.alwaysOriginal))
        view.addSubview(gpsIconImageView!)
        gpsIconImageView?.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalTo(self.view.snp.height)
            make.bottom.equalToSuperview()
        }
        
        gpsSignalLevelLabel = UILabel()
        gpsSignalLevelLabel?.textColor = .white
        gpsSignalLevelLabel?.textAlignment = .left
        gpsSignalLevelLabel?.font = UIFont.systemFont(ofSize: 10)
        view.addSubview(gpsSignalLevelLabel!)
        gpsSignalLevelLabel?.snp.makeConstraints { make in
            make.left.equalTo(gpsIconImageView!.snp.right).offset(5)
            make.top.equalTo(0)
            make.bottom.equalToSuperview().offset(-10)
        }
        
        gpsSignalLevelImageView = UIImageView(image: signal_0_Image)
        view.addSubview(gpsSignalLevelImageView!)
        gpsSignalLevelImageView?.snp.makeConstraints { make in
            make.left.equalTo(gpsIconImageView!.snp.right).offset(5)
            make.top.equalToSuperview()
            make.width.equalTo(self.view.snp.height)
            make.bottom.equalToSuperview()
        }
    }
    
    private func updateGpsSignal(signalValue: Int) {
        
        gpsSignalLevelLabel?.text = String(signalValue)
        
        if signalValue <= 0 {
            gpsSignalLevelImageView?.image = signal_0_Image
        } else if signalValue < 4 {
            gpsSignalLevelImageView?.image = signal_1_Image
        } else if signalValue < 7 {
            gpsSignalLevelImageView?.image = signal_2_Image
        } else if signalValue < 10 {
            gpsSignalLevelImageView?.image = signal_3_Image
        } else if signalValue < 13 {
            gpsSignalLevelImageView?.image = signal_4_Image
        } else {
            gpsSignalLevelImageView?.image = signal_5_Image
        }
    }
    
    @objc public override func update() {
        super.update()
        updateGpsSignal(signalValue: session?.state?.value.gpsSatellites ?? 0)
    }
}
