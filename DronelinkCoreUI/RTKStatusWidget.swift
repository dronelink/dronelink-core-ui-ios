//
//  RTKStatusWidget.swift
//  DronelinkCoreUI
//
//  Created by Patrick Verbeeten on 10/10/2020.
//  Copyright © 2020 Dronelink. All rights reserved.
//

import os
import Foundation
import UIKit
import SnapKit
import JavaScriptCore
import DronelinkCore
import MaterialComponents.MaterialPalettes
import Kingfisher
import SwiftyUserDefaults

public class RTKStatusWidget: DelegateWidget {
    let statusLabel = UILabel()
    let rtkLabel = UILabel()
    public var createManager: ((_ session: DroneSession) -> RTKManager?)?
    private var manager: RTKManager?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = DronelinkUI.Constants.overlayColor
        
        rtkLabel.font = rtkLabel.font.withSize(9)
        rtkLabel.text = "RTKStatusWidget.status.label".localized
        rtkLabel.textAlignment = .left
        rtkLabel.textColor = .lightGray
        view.addSubview(rtkLabel)
        
        statusLabel.text = "NetworkRTKStatus.value.0".localized
        statusLabel.textAlignment = .left
        statusLabel.textColor = .white
        statusLabel.adjustsFontSizeToFitWidth = true
        view.addSubview(statusLabel)
        
        let tapRtk = UITapGestureRecognizer(target: self, action: #selector(onRtkConfiguration))
        view.addGestureRecognizer(tapRtk)
        
        view.isHidden = true
    }
    
    public override func onInitialized(session: DroneSession) {
        manager = createManager?(session)
        
        DispatchQueue.main.async { [weak self] in
            self?.view.isHidden = self?.manager == nil
        }

        manager?.addUpdateListner(key: "RtkStatus") { (state: RTKState) in
            DispatchQueue.main.async { [weak self] in
                if (state.networkRTKStatus != .notSupported)
                {
                    self?.updateLabel(state)
                    self?.view.isHidden = false
                }
                else {
                    self?.view.isHidden = true
                }
            }
        }
    }
    
    @objc func onRtkConfiguration() {
        if let manager = manager, let widget = widgetFactory.createRTKMenuWidget(current: nil) as? RTKSettingsWidget {
            widget.set(manager: manager)
            present(widget, animated: true, completion: nil)
        }
    }
    
    func updateLabel(_ state: RTKState) {
        switch state.networkRTKStatus {
        
        case .notSupported, .disabled, .connecting, .connected, .timeout:
            statusLabel.text = "NetworkRTKStatus.value.\(state.networkRTKStatus.rawValue)".localized
            break
            
        case .error:
            statusLabel.text = state.networkServiceStateText
            break
        }
    }
    
    public override func updateViewConstraints() {
        super.updateViewConstraints()
        
        let defaultPadding = 8
        
        rtkLabel.snp.remakeConstraints { [weak self] make in
            make.left.equalToSuperview().offset(defaultPadding)
            make.right.equalToSuperview().offset(-defaultPadding)
            make.top.equalToSuperview().offset(2)
        }
        
        statusLabel.snp.remakeConstraints { [weak self] make in
            make.left.equalToSuperview().offset(defaultPadding)
            make.right.equalToSuperview().offset(-defaultPadding)
            make.top.equalTo(rtkLabel.snp.bottom)
        }
    }
}
