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
    public override func viewDidLoad() {
        super.viewDidLoad()
        iconImageView.image = DronelinkUI.loadImage(named: "downLinkIcon")?.withRenderingMode(.alwaysTemplate)
        iconImageView.tintColor = .white
    }
    
    @objc public override func update() {
        super.update()
        updateSignal(signalValue: session?.state?.value.downlinkSignalStrength ?? 0)
    }
}
