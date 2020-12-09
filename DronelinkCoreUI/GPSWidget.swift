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
            make.left.equalTo(gpsIconImageView?.bounds.size.width ?? 0)
            make.top.equalTo(0)
            make.bottom.equalToSuperview().offset(-10)
        }
        
        gpsSignalLevelImageView = UIImageView(image: DronelinkUI.loadImage(named: "gpsSignal0")?.withRenderingMode(.alwaysOriginal))
        view.addSubview(gpsSignalLevelImageView!)
        gpsSignalLevelImageView?.snp.makeConstraints { make in
            make.left.equalTo((gpsIconImageView?.bounds.size.width ?? 0) + 5)
            make.top.equalToSuperview()
            make.width.equalTo(self.view.snp.height)
            make.bottom.equalToSuperview()
        }
    }
    
    private func updateGpsSignal(signalValue: Int) {
        
        gpsSignalLevelLabel?.text = String(signalValue)
        
        var imageName = ""
        
        if signalValue <= 0 {
            imageName = "gpsSignal0"
        } else if signalValue < 2 {
            imageName = "gpsSignal1"
        } else if signalValue < 3 {
            imageName = "gpsSignal2"
        } else if signalValue < 4 {
            imageName = "gpsSignal3"
        } else if signalValue < 5 {
            imageName = "gpsSignal4"
        } else {
            imageName = "gpsSignal5"
        }
        
        gpsSignalLevelImageView?.image = DronelinkUI.loadImage(named: imageName)?.withRenderingMode(.alwaysOriginal)
        
    }
    
    @objc public override func update() {
        super.update()
        updateGpsSignal(signalValue: session?.state?.value.gpsSatellites ?? 0)
    }
}
