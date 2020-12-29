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

public class UplinkWidget: SignalWidget {
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        iconImageView.image = DronelinkUI.loadImage(named: "upLinkIcon")?.withRenderingMode(.alwaysOriginal)
        iconImageView.tintColor = .white
    }
    
    @objc public override func update() {
        super.update()
        updateSignal(signalValue: session?.state?.value.uplinkSignalStrength ?? 0)
    }
}
