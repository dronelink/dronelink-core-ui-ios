//
//  RTKSettingsWidget.swift
//  DronelinkCoreUI
//
//  Created by Patrick Verbeeten on 11/10/2020.
//  Copyright © 2020 Dronelink. All rights reserved.
//

import os
import Foundation
import UIKit
import SnapKit
import JavaScriptCore
import DronelinkCore
import MaterialComponents.MaterialPalettes
import MaterialComponents.MaterialTextFields
import MaterialComponents.MaterialButtons
import Kingfisher
import SwiftyUserDefaults

public class RTKSettingsWidget: Widget {
    let dismissButton = UIButton()
    let headingConfiguration = UILabel()
    let headingStatus = UILabel()
    var statusControls: [(label: UILabel, control: UIView)] = []
    var controls: [(label: UILabel, control: UIView)] = []
    let serverAddress = MDCTextField()
    let port = MDCTextField()
    let mountPoint = MDCTextField()
    let userName = MDCTextField()
    let password = MDCTextField()
    let confirm = MDCButton()
    let autoconnect = UISwitch()
    let enabled = UISwitch()
    let scroll = UIScrollView()
    let networkStatus = UILabel()
    let configStatus = UILabel()
    private var manager: RTKManager?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        modalPresentationStyle = .formSheet
        modalTransitionStyle = UIModalTransitionStyle.coverVertical
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        modalPresentationStyle = .formSheet
        modalTransitionStyle = UIModalTransitionStyle.coverVertical
    }
    
    public func set(manager: RTKManager) {
        self.manager = manager
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        }
        
        view.addShadow()
        
        view.backgroundColor = .black
        
        scroll.backgroundColor = .black
        view.addSubview(scroll)
        
        headingStatus.text = "RTKSettingsWidget.popover.status.heading".localized
        headingStatus.textColor = .white
        scroll.addSubview(headingStatus)
        
        headingConfiguration.text = "RTKSettingsWidget.popover.configuration.heading".localized
        headingConfiguration.textColor = .white
        scroll.addSubview(headingConfiguration)
        
        dismissButton.setImage(DronelinkUI.loadImage(named: "baseline_close_white_36pt"), for: .normal)
        dismissButton.tintColor = .white
        dismissButton.addTarget(self, action: #selector(onClose),for: .touchUpInside)
        view.addSubview(dismissButton)
        
        networkStatus.textColor = .white
        addStatus("RTKSettingsWidget.popover.status.channel".localized, networkStatus)
        configStatus.textColor = .white
        addStatus("RTKSettingsWidget.popover.status.configuration".localized, configStatus)
        
        let config = manager?.configuration
        
        enabled.tintColor = .white
        enabled.isOn = config?.enabled ?? false
        addField("RTKSettingsWidget.popover.configuration.enabled".localized, enabled)
        autoconnect.tintColor = .white
        autoconnect.isOn = config?.autoConnect ?? false
        addField("RTKSettingsWidget.popover.configuration.autoconnect".localized, autoconnect)
        serverAddress.tintColor = .white
        serverAddress.textColor = .white
        serverAddress.text = config?.serverAddress
        addField("RTKSettingsWidget.popover.configuration.serveraddress".localized, serverAddress)
        port.tintColor = .white
        port.textColor = .white
        port.keyboardType = .numberPad
        port.text = "\(config?.port ?? 2101)"
        addField("RTKSettingsWidget.popover.configuration.port".localized, port)
        mountPoint.tintColor = .white
        mountPoint.textColor = .white
        mountPoint.text = config?.mountPoint
        addField("RTKSettingsWidget.popover.configuration.mountpoint".localized, mountPoint)
        userName.tintColor = .white
        userName.textColor = .white
        userName.text = config?.userName
        addField("RTKSettingsWidget.popover.configuration.username".localized, userName)
        password.tintColor = .white
        password.textColor = .white
        password.isSecureTextEntry = true
        password.text = config?.password
        addField("RTKSettingsWidget.popover.configuration.password".localized, password)
        
        let scheme = MDCContainerScheme()
        scheme.colorScheme = MDCSemanticColorScheme(defaults: .materialDark201907)
        scheme.colorScheme.primaryColor = UIColor.darkGray
        confirm.applyContainedTheme(withScheme: scheme)
        confirm.setTitle("RTKSettingsWidget.popover.configuration.confirm".localized, for: .normal)
        confirm.setTitleColor(.white, for: .normal)
        confirm.addTarget(self, action: #selector(onConfirm),for: .touchUpInside)
        scroll.addSubview(confirm)
                
        manager?.addUpdateListner(key: "RtkConfiguration", closure: { (state: RTKState) in
            self.statusUpdate(state)
        })
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        manager?.removeUpdateListner(key: "RtkConfiguration")
    }
    
    private func statusUpdate(_ state: RTKState) {
        networkStatus.text = state.networkServiceStateText
        configStatus.text = state.configurationStatus
    }
    
    private func addField(_ title: String, _ control: UIView) {
        let label = UILabel()
        label.text = title
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 12)
        label.adjustsFontSizeToFitWidth = true
        scroll.addSubview(label)

        scroll.addSubview(control)

        controls.append((label: label, control: control))
    }
    
    private func addStatus(_ title: String, _ control: UILabel) {
        let label = UILabel()
        label.text = title
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 12)
        label.adjustsFontSizeToFitWidth = true
        scroll.addSubview(label)

        control.textColor = .white
        control.font = UIFont.systemFont(ofSize: 12)
        scroll.addSubview(control)

        statusControls.append((label: label, control: control))
    }
    
    public override func updateViewConstraints() {
        super.updateViewConstraints()
        
        let padding = 8
        let labelHeight = 30
        let labelWidth = 100
        scroll.snp.remakeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        dismissButton.snp.remakeConstraints { make in
            make.height.equalTo(24)
            make.width.equalTo(dismissButton.snp.height)
            make.right.equalToSuperview().offset(-padding)
            make.top.equalToSuperview().offset(padding)
        }
        view.bringSubviewToFront(dismissButton)
        
        headingStatus.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(padding)
            make.left.equalTo(scroll.safeAreaLayoutGuide.snp.left).offset(padding)
        }
        
        var previous: UIView = headingStatus
        for (label, control) in self.statusControls {
            control.snp.remakeConstraints { make in
                make.top.equalTo(previous.snp.bottom).offset(2)
                make.left.equalTo(label.snp.right).offset(padding)
                make.right.equalTo(scroll.safeAreaLayoutGuide.snp.right).offset(-padding)
                make.height.equalTo(15)
            }
            
            label.snp.remakeConstraints { make in
                make.top.equalTo(control.snp.top)
                make.left.equalTo(scroll.safeAreaLayoutGuide.snp.left).offset(padding)
                make.width.equalTo(labelWidth)
                make.height.equalTo(control.snp.height)
            }
            
            previous = control
        }
        
        headingConfiguration.snp.remakeConstraints { make in
            make.top.equalTo(previous.snp.bottom).offset(padding + 8)
            make.left.equalTo(scroll.safeAreaLayoutGuide.snp.left).offset(padding)
        }
        previous = headingConfiguration
        for (label, control) in self.controls {
            control.snp.remakeConstraints { make in
                make.top.equalTo(previous.snp.bottom).offset(2)
                make.left.equalTo(label.snp.right).offset(padding)
                make.right.equalTo(scroll.safeAreaLayoutGuide.snp.right).offset(-padding)
            }
            
            label.snp.remakeConstraints { make in
                make.bottom.equalTo(control.snp.bottom).offset(-8)
                make.left.equalTo(scroll.safeAreaLayoutGuide.snp.left).offset(padding)
                make.width.equalTo(labelWidth)
                make.height.equalTo(labelHeight)
            }
            
            previous = control
        }
        
        confirm.snp.remakeConstraints { make in
            make.top.equalTo(previous.snp.bottom).offset(padding)
            make.right.equalTo(scroll.safeAreaLayoutGuide.snp.right).offset(-padding)
            make.bottom.equalTo(scroll.contentLayoutGuide.snp.bottom).offset(-padding)
        }
        
    }
    
    @objc func onClose(sender: UIButton!) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func onConfirm(sender: UIButton!) {
        manager?.set(configuration: RTKConfigurationRecord(
            enabled: enabled.isOn,
            autoConnect: autoconnect.isOn,
            serverAddress: serverAddress.text,
            port: Int(port.text ?? "2021"),
            mountPoint: mountPoint.text,
            userName: userName.text,
            password: password.text
        ))
    
        dismiss(animated: true, completion: nil)
    }
}
