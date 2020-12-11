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
    
    public let captureButton = UIButton()
    public let captureModeImageView = UIImageView()
    public let countIndicatorLabel = UILabel()
    private var stopCameraCaptureCommand: Kernel.StopCaptureCameraCommand?
    private var startCameraCaptureCommand: Kernel.StartCaptureCameraCommand?
    
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
    
    private var cameraIsCapturing: Bool {
        session?.cameraState(channel: 0)?.value.isCapturing ?? false
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        configCaptureButton()
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
        
        captureModeImageView.tintColor = .black
        captureModeImageView.contentMode = .scaleAspectFit
        captureModeImageView.isUserInteractionEnabled = false
        view.addSubview(captureModeImageView)
        captureModeImageView.snp.makeConstraints { make in
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
    
    private func initializeVideoTimer() {
        videoTimeLabel.text = "00.00".localized
    }
    
    private func configCaptureButton() {
        captureButton.setImage(captureIcon, for: .normal)
        captureButton.addTarget(self, action: #selector(captureButtonClicked(_:)), for: .touchUpInside)
    }
    
    @objc func captureButtonClicked (_ sender:UIButton) {
        // If camera is capturing then add stop capture command else add start capture command
        captureButton.isEnabled = false
        
        var cmd: KernelCommand
        
        if cameraIsCapturing {
            cmd = Kernel.StopCaptureCameraCommand()
            self.stopCameraCaptureCommand = cmd as! Kernel.StopCaptureCameraCommand
        } else {
            cmd = Kernel.StartCaptureCameraCommand()
            self.startCameraCaptureCommand = cmd as! Kernel.StartCaptureCameraCommand
            
            if session?.cameraState(channel: 0)?.value.mode == .photo {
                activityIndicator.startAnimating()
            }
        }
        try? self.session?.add(command: cmd)
    }
    
    private func configCaptureModeImage(mode: DronelinkCore.Kernel.CameraPhotoMode?) {
        
        if session?.cameraState(channel: 0)?.value.mode == .photo {
            var image: UIImage?
            var count = ""
            
            switch mode {
            case .aeb:
                image = aebModeImage
                if let aeb = session?.cameraState(channel: 0)?.value.aebCount {
                    count =  aeb.rawValue
                }
            case .burst:
                image = burstModeImage
                if let burst = session?.cameraState(channel: 0)?.value.burstCount {
                    count =  burst.rawValue
                }
            case .ehdr:
                image = hdrModeImage
            case .hyperLight:
                image = hyperModeImage
            case .interval:
                image = timerModeImage
                if let interval = session?.cameraState(channel: 0)?.value.photoInterval {
                    count =  String(interval)
                }
            case .panorama:
                image = panoModeImage
            default:
                image = nil
            }
            
            if let modeImage = image {
                captureModeImageView.isHidden = false
                captureModeImageView.image = modeImage
            } else {
                captureModeImageView.isHidden = true
            }
            
            if count != "" {
                countIndicatorLabel.isHidden = false
                countIndicatorLabel.text = count
            } else {
                countIndicatorLabel.isHidden = true
            }
        } else {
            captureModeImageView.isHidden = true
            countIndicatorLabel.isHidden = true
        }
    }
    
    @objc public override func update() {
        super.update()
        captureButton.tintColor = (session?.cameraState(channel: 0)?.value.mode == .video) ? .red : .white
        guard let photoMode = (session?.cameraState(channel: 0)?.value.photoMode) else {return}
        configCaptureModeImage(mode: photoMode)
        
        let videoTimeInSeconds = session?.cameraState(channel: 0)?.value.currentVideoTimeInSeconds ?? 0
        
        videoTimeLabel.text = String(format:"%02d:%02d", (videoTimeInSeconds / 60), (videoTimeInSeconds % 60))
    }
    
    public override func onClosed(session: DroneSession) {
        super.onClosed(session: session)
        DispatchQueue.main.async {
            self.captureButton.isEnabled = false
        }
    }
    
    public override func onOpened(session: DroneSession) {
        super.onOpened(session: session)
        DispatchQueue.main.async {
            self.captureButton.isEnabled = true
        }
    }
    
    public override func onCommandFinished(session: DroneSession, command: KernelCommand, error: Error?) {
        
        super.onCommandFinished(session: session, command: command, error: error)
        
        if error != nil {
            DronelinkUI.shared.showSnackbar(text: error?.localizedDescription ?? "Unknown Error".localized)
        } else {
            if let startCameraCommand = self.startCameraCaptureCommand {
                self.startCameraCaptureCommand = nil
                DispatchQueue.main.async {
                    self.captureButton.isEnabled = (command.id == startCameraCommand.id)
                    
                    guard let mode = (session.cameraState(channel: 0)?.value.mode) else {return}
                    
                    if mode == .video {
                        
                        self.initializeVideoTimer()
                        self.videoTimeLabel.isHidden = false
                        self.captureButton.setImage(self.stopIcon, for: .normal)
                        
                    } else if mode == .photo {
                        
                        self.activityIndicator.stopAnimating()
                        AudioServicesPlaySystemSound(1108)
                    }
                    
                }
            } else if let stopCameraCommand = self.stopCameraCaptureCommand {
                self.stopCameraCaptureCommand = nil
                DispatchQueue.main.async {
                    self.captureButton.isEnabled = (command.id == stopCameraCommand.id)
                    
                    guard let mode = (session.cameraState(channel: 0)?.value.mode) else {return}
                    
                    if mode == .video && error == nil {
                        self.videoTimeLabel.isHidden = true
                        self.captureButton.setImage(self.captureIcon, for: .normal)
                    }
                }
            }
        }
        
        
      }
}
