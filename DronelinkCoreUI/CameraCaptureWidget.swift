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
import MaterialComponents.MaterialActivityIndicator

public class CameraCaptureWidget: CameraWidget {
    public override var updateInterval: TimeInterval { 0.1 }
    
    public let button = UIButton()
    public let activityBackgroundImageView = UIImageView()
    public let activityIndicator = MDCActivityIndicator()
    public let extraImageView = UIImageView()
    public let extraLabel = UILabel()
    public let timeLabel = UILabel()
    
    public var photoSystemSound: UInt32? = 1108
    public var videoStartSystemSound: UInt32? = 1117
    public var videoStopSystemSound: UInt32? = 1118
    public var videoColor = MDCPalette.red.accent400!
    public var photoColor = UIColor.white
    public var activityColor = MDCPalette.pink.accent400!
    public var activityImage = DronelinkUI.loadImage(named: "activityIcon")?.withRenderingMode(.alwaysTemplate)
    public var startImage = DronelinkUI.loadImage(named: "captureIcon")?.withRenderingMode(.alwaysTemplate)
    public var stopImage = DronelinkUI.loadImage(named: "stopIcon")?.withRenderingMode(.alwaysOriginal)
    public var sdCardMissing = DronelinkUI.loadImage(named: "sdCardMissing")?.withRenderingMode(.alwaysOriginal)
    public var aebModeImage = DronelinkUI.loadImage(named: "aebMode")?.withRenderingMode(.alwaysTemplate)
    public var burstModeImage = DronelinkUI.loadImage(named: "burstMode")?.withRenderingMode(.alwaysTemplate)
    public var hdrModeImage = DronelinkUI.loadImage(named: "hdrMode")?.withRenderingMode(.alwaysTemplate)
    public var hyperModeImage = DronelinkUI.loadImage(named: "hyperMode")?.withRenderingMode(.alwaysTemplate)
    public var timerModeImage = DronelinkUI.loadImage(named: "timerMode")?.withRenderingMode(.alwaysTemplate)
    public var panoModeImage = DronelinkUI.loadImage(named: "panoMode")?.withRenderingMode(.alwaysTemplate)
    public var highResolutionModeImage = DronelinkUI.loadImage(named: "highResolutionMode")?.withRenderingMode(.alwaysTemplate)
    
    private var pendingCommand: KernelCommand?
    private var previousCapturing = false
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        button.addShadow()
        button.setImage(startImage, for: .normal)
        button.addTarget(self, action: #selector(onTapped(_:)), for: .touchUpInside)
        button.isEnabled = false
        view.addSubview(button)
        button.snp.makeConstraints { [weak self] make in
            make.top.equalToSuperview().offset(5)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-15)
        }
        
        activityBackgroundImageView.tintColor = .white
        activityBackgroundImageView.image = activityImage
        activityBackgroundImageView.contentMode = .scaleAspectFit
        activityBackgroundImageView.isUserInteractionEnabled = false
        view.addSubview(activityBackgroundImageView)
        activityBackgroundImageView.snp.makeConstraints { [weak self] make in
            make.edges.equalTo(button)
        }
        
        activityIndicator.cycleColors = [activityColor]
        activityIndicator.indicatorMode = .indeterminate
        activityIndicator.radius = 22
        activityIndicator.strokeWidth = 2.5
        activityIndicator.isUserInteractionEnabled = false
        view.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { [weak self] make in
            make.edges.equalTo(button)
        }
        
        extraImageView.tintColor = .black
        extraImageView.contentMode = .scaleAspectFit
        extraImageView.isUserInteractionEnabled = false
        view.addSubview(extraImageView)
        extraImageView.snp.makeConstraints { [weak self] make in
            make.center.equalTo(button.snp.center)
            make.height.equalTo(22)
            make.width.equalTo(22)
        }
        
        extraLabel.adjustsFontSizeToFitWidth = true
        extraLabel.minimumScaleFactor = 0.5
        extraLabel.numberOfLines = 1
        extraLabel.textColor = .black
        extraLabel.isUserInteractionEnabled = false
        extraLabel.font = UIFont.systemFont(ofSize: 10)
        extraLabel.backgroundColor = UIColor.white
        extraLabel.textAlignment = .center
        extraLabel.layer.cornerRadius = 6
        extraLabel.layer.masksToBounds = true
        view.addSubview(extraLabel)
        extraLabel.snp.makeConstraints { [weak self] make in
            make.top.equalTo(extraImageView.snp.bottom).offset(-11)
            make.left.equalTo(extraImageView.snp.left).offset(-3)
            make.height.equalTo(12)
            make.width.equalTo(12)
        }
        
        timeLabel.addShadow()
        timeLabel.textColor = .white
        timeLabel.textAlignment = .center
        timeLabel.isUserInteractionEnabled = false
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.isHidden = true
        view.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { [weak self] make in
            make.top.equalTo(button.snp.bottom).offset(5)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    @objc func onTapped(_ sender: UIButton) {
        button.isEnabled = false
        let command: KernelCommand = (state?.isCapturingContinuous ?? false) ? Kernel.StopCaptureCameraCommand(channel: channelResolved) : Kernel.StartCaptureCameraCommand(channel: channelResolved)
        do {
            try? session?.add(command: command)
            pendingCommand = command
        }
    }
    
    @objc public override func update() {
        super.update()
        
        var sound: UInt32?
        
        if !(state?.isCapturingPhotoInterval ?? false) {
            if state?.isCapturing ?? false {
                if !previousCapturing {
                    switch state?.mode ?? .unknown {
                    case .photo:
                        sound = photoSystemSound
                        break
                        
                    case .video:
                        sound = videoStartSystemSound
                        break
                        
                    default:
                        break
                    }
                }
            }
            else {
                if previousCapturing {
                    if state?.mode == .video {
                        sound = videoStopSystemSound
                    }
                }
            }
        }
        
        if let sound = sound {
            AudioServicesPlaySystemSound(sound)
        }
        
        previousCapturing = state?.isCapturing ?? false
        
        button.tintColor = state?.mode == .video ? videoColor : photoColor
        button.isEnabled = session != nil && pendingCommand == nil && (!(state?.isCapturing ?? false) || state?.isCapturingContinuous ?? false)
        button.setImage(state?.isCapturingContinuous ?? false ? stopImage : startImage, for: .normal)
        
        activityBackgroundImageView.alpha = button.isEnabled ? 1.0 : 0.5
        if pendingCommand == nil && !(state?.isBusy ?? false) {
            if activityIndicator.isAnimating {
                activityIndicator.stopAnimating()
            }
        }
        else {
            if !activityIndicator.isAnimating {
                activityIndicator.startAnimating()
            }
        }
        
        var extraImage: UIImage?
        var extraText: String?
        
        if state?.storageLocation == .sdCard, !(state?.isSDCardInserted ?? true) {
            extraImage = sdCardMissing
        }
        
        if extraImage == nil, state?.mode == .photo {
            switch state?.photoMode ?? .unknown {
            case .aeb:
                extraImage = aebModeImage
                extraText = state?.aebCount?.rawValue
                break
                
            case .burst:
                extraImage = burstModeImage
                extraText = state?.burstCount?.rawValue
                break
                
            case .ehdr:
                extraImage = hdrModeImage
                break
                
            case .hyperLight:
                extraImage = hyperModeImage
                break
                
            case .interval:
                if !(state?.isCapturingPhotoInterval ?? false) {
                    extraImage = timerModeImage
                    if let interval = state?.photoInterval {
                        extraText = String(interval)
                    }
                }
                break
                
            case .panorama:
                extraImage = panoModeImage
                break
                
            case .highResolution:
                extraImage = highResolutionModeImage
                break
                
            default:
                break
            }
        }
        
        extraImageView.image = extraImage
        extraImageView.isHidden = extraImage == nil
        
        if extraText?.isEmpty ?? true {
            extraLabel.isHidden = true
        } else {
            extraLabel.isHidden = false
            extraLabel.text = extraText
        }
        
        if let currentVideoTime = state?.currentVideoTime {
            timeLabel.isHidden = false
            timeLabel.text = Dronelink.shared.format(formatter: "timeElapsed", value: currentVideoTime)
        }
        else {
            timeLabel.isHidden = true
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
                DronelinkUI.shared.showSnackbar(text: error as? String ?? error.localizedDescription)
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.update()
            }
        }
    }
    
    public override func onCameraFileGenerated(session: DroneSession, file: CameraFile) {
        super.onCameraFileGenerated(session: session, file: file)
        if let photoSystemSound = photoSystemSound, state?.mode == .photo, state?.photoMode == .interval, file.channel == channel {
            DispatchQueue.main.async {
                AudioServicesPlaySystemSound(photoSystemSound)
            }
        }
    }
}
