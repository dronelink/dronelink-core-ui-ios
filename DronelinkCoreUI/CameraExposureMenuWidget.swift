//
//  CameraExposureMenuWidget.swift
//  DronelinkCoreUI
//
//  Created by santiago on 15/4/21.
//

import Foundation
import UIKit
import DronelinkCore
import SnapKit
    
public class CameraExposureMenuWidget: UpdatableWidget, UIPickerViewDataSource, UIPickerViewDelegate {
    
    public let settingsStackView = UIStackView()
    
    public var channel: UInt = 0
    public var cameraState: CameraStateAdapter? { session?.cameraState(channel: channel)?.value }
    public var isAutoIsoEnabled = false
    public let isoSettingsView = UIView()
    public let isoTitleLabel = UILabel()
    public let isoAutoButton = UIButton()
    public var isoAutoButtonActiveColor = UIColor.white
    public var isoAutoButtonInactiveColor = UIColor.black
    public let isoSlider = UISlider()
    
    public let shutterSettingsView = UIView()
    public let shutterTitleLabel = UILabel()
    public let shutterPickerView = UIPickerView()
    public var currentShutterSpeed: Kernel.CameraShutterSpeed?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        
        settingsStackView.axis = .vertical
        settingsStackView.distribution = .fill
        settingsStackView.spacing = 16
        view.addSubview(settingsStackView)
        settingsStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(8)
            make.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }
        
        isoSettingsView.addSubview(isoTitleLabel)
        isoTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.trailing.equalToSuperview()
            make.leading.equalToSuperview()
            make.height.equalTo(20)
        }
        isoTitleLabel.text = "CameraExposureMenu.iso".localized
        
        isoSettingsView.addSubview(isoAutoButton)
        isoAutoButton.snp.makeConstraints { make in
            make.top.equalTo(isoTitleLabel.snp.bottom).offset(8)
            make.bottom.equalToSuperview()
            make.leading.equalToSuperview()
            make.width.equalTo(40)
            make.height.equalTo(40)
        }
        isoAutoButton.titleLabel?.font = .systemFont(ofSize: 10)
        isoAutoButton.setTitle("CameraExposureMenu.autoIso".localized, for: .normal)
        isoAutoButton.layer.borderWidth = 2
        isoAutoButton.layer.borderColor = UIColor.white.cgColor
        isoAutoButton.layer.cornerRadius = 20
        isoAutoButton.addTarget(self, action: #selector(onAutoIso), for: .touchUpInside)
        
        isoSettingsView.addSubview(isoSlider)
        isoSlider.snp.makeConstraints { make in
            make.top.equalTo(isoAutoButton.snp.top)
            make.bottom.equalToSuperview()
            make.trailing.equalToSuperview()
            make.leading.equalTo(isoAutoButton.snp.trailing).offset(8)
        }
        isoSlider.isContinuous = false
        isoSlider.maximumValue = Float(Kernel.CameraISO.allCases.count - 2)
        isoSlider.addTarget(self, action: #selector(onIsoValueChanged(_:)), for: .valueChanged)
        settingsStackView.addArrangedSubview(isoSettingsView)
        
        shutterSettingsView.addSubview(shutterTitleLabel)
        shutterTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.trailing.equalToSuperview()
            make.leading.equalToSuperview()
            make.height.equalTo(20)
        }
        shutterTitleLabel.text = "CameraExposureMenu.shutter".localized
        
        shutterSettingsView.addSubview(shutterPickerView)
        shutterPickerView.dataSource = self
        shutterPickerView.delegate = self
        shutterPickerView.snp.makeConstraints { make in
            make.top.equalTo(shutterTitleLabel.snp.bottom).offset(8)
            make.bottom.equalToSuperview()
            make.trailing.equalToSuperview()
            make.leading.equalToSuperview()
        }

        settingsStackView.addArrangedSubview(shutterSettingsView)
        
        isAutoIsoEnabled = cameraState?.iso == .auto
        isoSlider.value = Float(Kernel.CameraISO.allCases.firstIndex(of: cameraState?.iso ?? .auto) ?? 0)
        currentShutterSpeed = cameraState?.shutterSpeed ?? .unknown
    }
    
    @objc public func onIsoValueChanged(_ sender: UISlider) {
        sender.value = round(sender.value)
        isAutoIsoEnabled = false
        updateISO()
    }
    
    @objc public func onAutoIso() {
        isAutoIsoEnabled = !isAutoIsoEnabled
        updateISO()
    }
    
    private func updateISO() {
        if isAutoIsoEnabled {
            isoAutoButton.backgroundColor = isoAutoButtonActiveColor
            isoAutoButton.setTitleColor(isoAutoButtonInactiveColor, for: .normal)
        } else {
            isoAutoButton.backgroundColor = isoAutoButtonInactiveColor
            isoAutoButton.setTitleColor(isoAutoButtonActiveColor, for: .normal)
        }
        
        var command = Kernel.ISOCameraCommand()
        command.iso = isAutoIsoEnabled ? .auto : getIsoValueFromSlider()
        do {
            try? session?.add(command: command)
        }
        print(command)
    }
    
    private func updateShutterSpeed() {
        guard let currentShutterSpeed = currentShutterSpeed else { return }
        var command = Kernel.ShutterSpeedCameraCommand()
        command.shutterSpeed = currentShutterSpeed
        do {
            try? session?.add(command: command)
        }
        print(command)
    }
    
    private func getIsoValueFromSlider() -> Kernel.CameraISO {
        let value = Int(isoSlider.value)
        guard value < Kernel.CameraISO.allCases.count - 1 else { return .unknown }
        return Kernel.CameraISO.allCases[value + 1]
    }
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Kernel.CameraShutterSpeed.allCases.count
    }
    
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Kernel.CameraShutterSpeed.allCases[row].rawValue
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        currentShutterSpeed = Kernel.CameraShutterSpeed.allCases[row]
        updateShutterSpeed()
    }
    
}
