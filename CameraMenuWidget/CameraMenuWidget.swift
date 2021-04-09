//
//  CameraMenuWidget.swift
//  DronelinkCoreUI
//
//  Created by santiago on 2/4/21.
//

import Foundation
import UIKit
import DronelinkCore
import SnapKit

class CameraMenuWidget: UpdatableWidget, SettingsTableDelegate, SettingsOptionsDelegate {

    public let submenusStackView = UIStackView()
    public let photoSettingsButton = UIButton()
    public let videoSettingsButton = UIButton()
    public let generalSettingsButton = UIButton()
    public let photoSettingsViewController = SettingsTableViewController()
    public let videoSettingsViewController = SettingsTableViewController()
    public let generalSettingsViewController = SettingsTableViewController()
    public let selectedIndicatorView = UIView()
    public let mainView = UIView()
    public let settingOptionsViewController = SettingOptionsViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        submenusStackView.backgroundColor = UIColor(red: 30, green: 30, blue: 30)
        mainView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        
        view.addSubview(submenusStackView)
        submenusStackView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.height.equalTo(48)
        }

        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.top.equalTo(submenusStackView.snp.bottom)
            make.height.equalTo(240)
        }
        submenusStackView.axis = .horizontal
        submenusStackView.addArrangedSubview(photoSettingsButton)
        submenusStackView.addArrangedSubview(videoSettingsButton)
        submenusStackView.addArrangedSubview(generalSettingsButton)
        submenusStackView.distribution = .fillEqually
        submenusStackView.spacing = 0
        submenusStackView.alignment = .fill
        
        photoSettingsButton.setImage(DronelinkUI.loadImage(named: "camera_setting_capture_deselected"), for: .normal)
        photoSettingsButton.setImage(DronelinkUI.loadImage(named: "camera_setting_capture_selected"), for: .selected)
        videoSettingsButton.setImage(DronelinkUI.loadImage(named: "camera_setting_video_deselected"), for: .normal)
        videoSettingsButton.setImage(DronelinkUI.loadImage(named: "camera_setting_video_selected"), for: .selected)
        generalSettingsButton.setImage(DronelinkUI.loadImage(named: "camera_setting_custom_deselected"), for: .normal)
        generalSettingsButton.setImage(DronelinkUI.loadImage(named: "camera_setting_custom_selected"), for: .selected)
        
        [photoSettingsButton, videoSettingsButton, generalSettingsButton].forEach {
            $0.tintColor = .white
            $0.imageEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            $0.addTarget(self, action: #selector(updateSelectedView(selectedButton:)), for: .touchUpInside)
        }
        
        view.addSubview(selectedIndicatorView)
        selectedIndicatorView.backgroundColor = .green
        
        mainView.addSubview(photoSettingsViewController.view)
        mainView.addSubview(videoSettingsViewController.view)
        mainView.addSubview(generalSettingsViewController.view)
        [photoSettingsViewController, videoSettingsViewController, generalSettingsViewController].forEach {
            $0.view.snp.makeConstraints { make in make.edges.equalToSuperview() }
            $0.view.backgroundColor = .clear
            $0.view.isHidden = true
            addChild($0)
            $0.didMove(toParent: self)
        }
        photoSettingsViewController.settingsDelegate = self
        photoSettingsViewController.settings = [.photoMode, .imageSize, .imageFormat, .whiteBalance]
        videoSettingsViewController.settingsDelegate = self
        videoSettingsViewController.settings = [.videoSize, .videoFormat, .ntscPal]
        generalSettingsViewController.settingsDelegate = self
        generalSettingsViewController.settings = []
        updateSelectedView(selectedButton: photoSettingsButton)
        
        view.addSubview(settingOptionsViewController.view)
        settingOptionsViewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        settingOptionsViewController.view.isHidden = true
        settingOptionsViewController.delegate = self
        addChild(settingOptionsViewController)
        settingOptionsViewController.didMove(toParent: self)
    }
    
    override func update() {
        super.update()
    }
    
    @objc public func updateSelectedView(selectedButton: UIButton) {
        guard let currentMainViewController = getViewControllerForButton(selectedButton) else { return }
        [photoSettingsButton, videoSettingsButton, generalSettingsButton].forEach { $0.isSelected = false }
        selectedButton.isSelected = true
        [photoSettingsViewController, videoSettingsViewController, generalSettingsViewController].forEach { $0.view.isHidden = true }
        currentMainViewController.view.isHidden = false
        
        selectedIndicatorView.snp.remakeConstraints { make in
            make.bottom.equalTo(selectedButton.snp.bottom)
            make.leading.equalTo(selectedButton.snp.leading)
            make.trailing.equalTo(selectedButton.snp.trailing)
            make.height.equalTo(4)
        }
    }
    
    private func getViewControllerForButton(_ selectedButton: UIButton) -> UIViewController? {
        if selectedButton == photoSettingsButton {
            return photoSettingsViewController
        }
        if selectedButton == videoSettingsButton {
            return videoSettingsViewController
        }
        if selectedButton == generalSettingsButton {
            return generalSettingsViewController
        }
        return nil
    }
    
    func showSettingOptions(setting: CameraMenuSetting) {
        settingOptionsViewController.view.isHidden = false
        mainView.isHidden = true
        submenusStackView.isHidden = true
        settingOptionsViewController.setting = setting
    }
    
    func hideSettingOptions() {
        settingOptionsViewController.view.isHidden = true
        mainView.isHidden = false
        submenusStackView.isHidden = false
    }
    
    func didSelectOption(_ option: CameraMenuOption, for setting: CameraMenuSetting) {
        if setting == .photoMode {
            guard let option = option as? Kernel.CameraPhotoMode else { return }
            var command = Kernel.PhotoModeCameraCommand()
            command.photoMode = option
            do {
                try? session?.add(command: command)
            }
        } else if setting == .imageSize {
            guard let option = option as? Kernel.CameraPhotoAspectRatio else { return }
            var command = Kernel.PhotoAspectRatioCameraCommand()
            command.photoAspectRatio = option
            do {
                try? session?.add(command: command)
            }
        } else if setting == .imageFormat {
            guard let option = option as? Kernel.CameraPhotoFileFormat else { return }
            var command = Kernel.PhotoFileFormatCameraCommand()
            command.photoFileFormat = option
            do {
                try? session?.add(command: command)
            }
        } else if setting == .whiteBalance {
            guard let option = option as? Kernel.CameraWhiteBalancePreset else { return }
            var command = Kernel.WhiteBalancePresetCameraCommand()
            command.whiteBalancePreset = option
            do {
                try? session?.add(command: command)
            }
        } else if setting == .videoSize {
            guard let option = option as? Kernel.CameraVideoResolution else { return }
            var command = Kernel.VideoResolutionFrameRateCameraCommand()
            command.videoResolution = option
            do {
                try? session?.add(command: command)
            }
        } else if setting == .videoFormat {
            guard let option = option as? Kernel.CameraVideoFileFormat else { return }
            var command = Kernel.VideoFileFormatCameraCommand()
            command.videoFileFormat = option
            do {
                try? session?.add(command: command)
            }
        }  else if setting == .ntscPal {
            guard let option = option as? Kernel.CameraVideoStandard else { return }
            var command = Kernel.VideoStandardCameraCommand()
            command.videoStandard = option
            do {
                try? session?.add(command: command)
            }
        }
        
        hideSettingOptions()
    }
}
