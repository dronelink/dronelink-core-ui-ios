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

public class UplinkWidget: GenericSignalWidget {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        iconImageView?.image = DronelinkUI.loadImage(named: "upLinkIcon")?.withRenderingMode(.alwaysOriginal)
    }
    
    @objc public override func update() {
        super.update()
        updateSignal(signalValue: session?.state?.value.uplinkSignalStrength ?? 0)
    }
}
