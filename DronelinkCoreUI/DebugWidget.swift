//
//  DebugWidget.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 6/3/21.
//  Copyright © 2021 Dronelink. All rights reserved.
//

import Foundation
import UIKit
import DronelinkCore
import SnapKit

public class DebugWidget: UpdatableWidget {
    private let textView = UITextView()
    public override var updateInterval: TimeInterval { 0.25 }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addShadow()
        view.layer.cornerRadius = DronelinkUI.Constants.cornerRadius
        view.backgroundColor = DronelinkUI.Constants.overlayColor
        
        textView.backgroundColor = UIColor.clear
        textView.font = UIFont.boldSystemFont(ofSize: 14)
        textView.textColor = UIColor.white
        textView.isScrollEnabled = true
        textView.isEditable = false
        view.addSubview(textView)
        
        textView.snp.makeConstraints { [weak self] make in
            make.edges.equalToSuperview()
        }
    }
    
    @objc open override func update() {
        super.update()
        
        var values: [String] = []
        
        if let ultrasonicAltitude = session?.state?.value.ultrasonicAltitude {
            values.append("Ultrasonic Altitude: \(Double(round(10 * ultrasonicAltitude)/10))")
        }
        
        if let cameraState = session?.cameraState(channel: 0)?.value {
            if let focusRingValue = cameraState.focusRingValue {
                values.append("Focus ring value: \(focusRingValue)")
            }
            
            if let focusRingValue = cameraState.focusRingMax {
                values.append("Focus ring max: \(focusRingValue)")
            }
        }
        else {
            values.append("Drone disconnected...")
        }
        
        textView.text = values.joined(separator: "\n")
    }
}
