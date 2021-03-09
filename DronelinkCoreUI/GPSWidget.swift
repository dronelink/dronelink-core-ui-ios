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

public class GPSWidget: UpdatableWidget {
    public let iconImageView = UIImageView(image: DronelinkUI.loadImage(named: "signalIcon")?.withRenderingMode(.alwaysOriginal))
    public let signalLevelLabel = UILabel()
    public let signalLevelImageView = UIImageView(image: DronelinkUI.loadImage(named: "signal0")?.withRenderingMode(.alwaysOriginal))
    
    public let signal0Image = DronelinkUI.loadImage(named: "signal0")?.withRenderingMode(.alwaysOriginal)
    public let signal1Image = DronelinkUI.loadImage(named: "signal1")?.withRenderingMode(.alwaysOriginal)
    public let signal2Image = DronelinkUI.loadImage(named: "signal2")?.withRenderingMode(.alwaysOriginal)
    public let signal3Image = DronelinkUI.loadImage(named: "signal3")?.withRenderingMode(.alwaysOriginal)
    public let signal4Image = DronelinkUI.loadImage(named: "signal4")?.withRenderingMode(.alwaysOriginal)
    public let signal5Image = DronelinkUI.loadImage(named: "signal5")?.withRenderingMode(.alwaysOriginal)
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        iconImageView.addShadow()
        view.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { [weak self] make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalTo(view.snp.height)
            make.bottom.equalToSuperview()
        }
        
        signalLevelLabel.addShadow()
        signalLevelLabel.textColor = .white
        signalLevelLabel.textAlignment = .left
        signalLevelLabel.font = UIFont.systemFont(ofSize: 10)
        view.addSubview(signalLevelLabel)
        signalLevelLabel.snp.makeConstraints { [weak self] make in
            make.left.equalTo(iconImageView.snp.right).offset(1)
            make.top.equalTo(0)
            make.bottom.equalToSuperview().offset(-10)
        }
        
        signalLevelImageView.addShadow()
        view.addSubview(signalLevelImageView)
        signalLevelImageView.snp.makeConstraints { [weak self] make in
            make.left.equalTo(iconImageView.snp.right).offset(5)
            make.top.equalToSuperview()
            make.width.equalTo(view.snp.height)
            make.bottom.equalToSuperview()
        }
    }
    
    @objc public override func update() {
        super.update()

        guard
            let satellites = session?.state?.value.gpsSatellites,
            let strength = session?.state?.value.gpsSignalStrength
        else {
            signalLevelLabel.text = ""
            signalLevelLabel.isHidden = true
            signalLevelImageView.image = signal0Image
            return
        }
        
        signalLevelLabel.text = "\(satellites)"
        signalLevelLabel.isHidden = false
        
        if strength == 0 {
            signalLevelImageView.image = signal0Image
        }
        else if strength <= 0.2 {
            signalLevelImageView.image = signal1Image
        }
        else if strength <= 0.4 {
            signalLevelImageView.image = signal2Image
        }
        else if strength <= 0.6 {
            signalLevelImageView.image = signal3Image
        }
        else if strength <= 0.8 {
            signalLevelImageView.image = signal4Image
        }
        else {
            signalLevelImageView.image = signal5Image
        }
    }
}
