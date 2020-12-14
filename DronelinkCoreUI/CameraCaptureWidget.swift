//
//  CameraCaptureWidget.swift
//  DronelinkCoreUI
//
//  Created by Nicolas Torres on 3/12/20.
//  Copyright © 2020 Dronelink. All rights reserved.
//
import UIKit
import AVFoundation
import DronelinkCore
import MaterialComponents.MaterialPalettes
import MaterialComponents.MaterialButtons
import MaterialComponents.MaterialButtons_Theming
import MaterialComponents.MaterialActivityIndicator
import MarqueeLabel

public class CameraCaptureWidget: UpdatableWidget {
    public var channel: UInt = 0
    private var cameraState: CameraStateAdapter? { session?.cameraState(channel: channel)?.value }
    
    public let captureButton = UIButton()
    public let capturePhotoModeImageView = UIImageView()
    public let countIndicatorLabel = UILabel()
    public let activityIndicator = MDCActivityIndicator()
    public let captureIcon = DronelinkUI.loadImage(named: "captureIcon")?.withRenderingMode(.alwaysTemplate)
    public let stopIcon = DronelinkUI.loadImage(named: "stopIcon")?.withRenderingMode(.alwaysOriginal)
    public let aebModeImage = DronelinkUI.loadImage(named: "aebMode")?.withRenderingMode(.alwaysTemplate)
    public let burstModeImage = DronelinkUI.loadImage(named: "burstMode")?.withRenderingMode(.alwaysTemplate)
    public let hdrModeImage = DronelinkUI.loadImage(named: "hdrMode")?.withRenderingMode(.alwaysTemplate)
    public let hyperModeImage = DronelinkUI.loadImage(named: "hyperMode")?.withRenderingMode(.alwaysTemplate)
    public let timerModeImage = DronelinkUI.loadImage(named: "timerMode")?.withRenderingMode(.alwaysTemplate)
    public let panoModeImage = DronelinkUI.loadImage(named: "panoMode")?.withRenderingMode(.alwaysTemplate)
    public let videoTimeLabel = UILabel()
    
    private var pendingCommand: KernelCommand?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        captureButton.setImage(captureIcon, for: .normal)
        captureButton.addTarget(self, action: #selector(onTapped(_:)), for: .touchUpInside)
        captureButton.isEnabled = false
        view.addSubview(captureButton)
        captureButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(5)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-15)
        }
        
        activityIndicator.cycleColors = [.darkGray]
        activityIndicator.indicatorMode = .indeterminate
        activityIndicator.isUserInteractionEnabled = false
        view.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(5)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-15)
        }
        
        capturePhotoModeImageView.tintColor = .black
        capturePhotoModeImageView.contentMode = .scaleAspectFit
        capturePhotoModeImageView.isUserInteractionEnabled = false
        view.addSubview(capturePhotoModeImageView)
        capturePhotoModeImageView.snp.makeConstraints { make in
            make.center.equalTo(captureButton.snp.center)
            make.height.equalTo(20)
            make.width.equalTo(20)
        }
        
        countIndicatorLabel.textColor = .black
        countIndicatorLabel.isUserInteractionEnabled = false
        countIndicatorLabel.font = UIFont.systemFont(ofSize: 10)
        view.addSubview(countIndicatorLabel)
        countIndicatorLabel.textAlignment = .right
        countIndicatorLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().offset(-5)
        }
        
        videoTimeLabel.textColor = .white
        videoTimeLabel.textAlignment = .center
        videoTimeLabel.isUserInteractionEnabled = false
        videoTimeLabel.font = UIFont.systemFont(ofSize: 12)
        videoTimeLabel.isHidden = true
        view.addSubview(videoTimeLabel)
        videoTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(captureButton.snp.bottom).offset(5)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    @objc func onTapped(_ sender: UIButton) {
        captureButton.isEnabled = false
        let command: KernelCommand = (cameraState?.isCapturing ?? false) ? Kernel.StopCaptureCameraCommand() : Kernel.StartCaptureCameraCommand()
        do {
            try? session?.add(command: command)
            pendingCommand = command
        }
    }
    
    @objc public override func update() {
        super.update()
        
        captureButton.tintColor = cameraState?.mode == .video ? MDCPalette.red.accent400 : .white
        captureButton.isEnabled = pendingCommand == nil && session != nil
        
        var photoModeImage: UIImage?
        var count = ""
        
        switch cameraState?.photoMode ?? .unknown {
        case .aeb:
            photoModeImage = aebModeImage
            if let aeb = cameraState?.aebCount {
                count = "\(aeb)"
            }
            break
            
        case .burst:
            photoModeImage = burstModeImage
            if let burst = cameraState?.burstCount {
                count = "\(burst)"
            }
            break
            
        case .ehdr:
            photoModeImage = hdrModeImage
            break
            
        case .hyperLight:
            photoModeImage = hyperModeImage
            break
            
        case .interval:
            photoModeImage = timerModeImage
            if let interval = cameraState?.photoInterval {
                count = String(interval)
            }
            break
            
        case .panorama:
            photoModeImage = panoModeImage
            break
            
        default:
            break
        }
        
        capturePhotoModeImageView.image = photoModeImage
        capturePhotoModeImageView.isHidden = cameraState?.mode != .photo
        
        if count.isEmpty {
            countIndicatorLabel.isHidden = false
            countIndicatorLabel.text = count
        } else {
            countIndicatorLabel.isHidden = true
        }
        
        if let currentVideoTime = cameraState?.currentVideoTime {
            videoTimeLabel.isHidden = false
            videoTimeLabel.text = Dronelink.shared.format(formatter: "timeElapsed", value: currentVideoTime)
            captureButton.setImage(stopIcon, for: .normal)
        }
        else {
            videoTimeLabel.isHidden = true
            captureButton.setImage(captureIcon, for: .normal)
        }
    }
    
    public override func onClosed(session: DroneSession) {
        super.onClosed(session: session)
        pendingCommand = nil
    }
    
    public override func onCommandFinished(session: DroneSession, command: KernelCommand, error: Error?) {
        super.onCommandFinished(session: session, command: command, error: error)
        
        if pendingCommand?.id == command.id {
            pendingCommand = nil
            if let error = error {
                DronelinkUI.shared.showSnackbar(text: error.localizedDescription)
            }
            
            if let command = command as? Kernel.StartCaptureCameraCommand {
                DispatchQueue.main.async {
                    if self.cameraState?.mode == .photo {
                        AudioServicesPlaySystemSound(1108)
                    }
                }
            }
        }
    }
}
