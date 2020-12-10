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
    
    public var captureButton: UIButton?
    public var captureModeImageView: UIImageView?
    public var countIndicatorLabel: UILabel?
    private var stopCameraCaptureCommand: Kernel.StopCaptureCameraCommand?
    private var startCameraCaptureCommand: Kernel.StartCaptureCameraCommand?
    
    public var activityIndicator: MDCActivityIndicator?
    
    private var captureIcon = DronelinkUI.loadImage(named: "captureIcon")?.withRenderingMode(.alwaysTemplate)
    private var stopIcon = DronelinkUI.loadImage(named: "stopIcon")?.withRenderingMode(.alwaysOriginal)
    
    private var aebModeImage = DronelinkUI.loadImage(named: "aebMode")?.withRenderingMode(.alwaysTemplate)
    private var burstModeImage = DronelinkUI.loadImage(named: "burstMode")?.withRenderingMode(.alwaysTemplate)
    private var hdrModeImage = DronelinkUI.loadImage(named: "hdrMode")?.withRenderingMode(.alwaysTemplate)
    private var hyperModeImage = DronelinkUI.loadImage(named: "hyperMode")?.withRenderingMode(.alwaysTemplate)
    private var timerModeImage = DronelinkUI.loadImage(named: "timerMode")?.withRenderingMode(.alwaysTemplate)
    private var panoModeImage = DronelinkUI.loadImage(named: "panoMode")?.withRenderingMode(.alwaysTemplate)
    
    private var originalDate: Date?
    private var videoTimer : Timer?
    
    public var videoTimeLabel: UILabel?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        captureButton = UIButton()
        configCaptureButton()
        view.addSubview(captureButton!)
        captureButton?.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(5)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-15)
        }
        
        activityIndicator = MDCActivityIndicator()
        activityIndicator?.cycleColors = [.darkGray]
        activityIndicator?.indicatorMode = .indeterminate
        activityIndicator?.isUserInteractionEnabled = false
        view.addSubview(activityIndicator!)
        activityIndicator?.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(5)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-15)
        }
        
        captureModeImageView = UIImageView()
        captureModeImageView?.tintColor = .black
        captureModeImageView?.contentMode = .scaleAspectFit
        captureModeImageView?.isUserInteractionEnabled = false
        view.addSubview(captureModeImageView!)
        captureModeImageView?.snp.makeConstraints { make in
            make.center.equalTo(captureButton!.snp.center)
            make.height.equalTo(20)
            make.width.equalTo(20)
        }
        
        countIndicatorLabel = UILabel()
        countIndicatorLabel?.textColor = .black
        countIndicatorLabel?.isUserInteractionEnabled = false
        countIndicatorLabel?.font = UIFont.systemFont(ofSize: 10)
        view.addSubview(countIndicatorLabel!)
        countIndicatorLabel?.textAlignment = .right
        countIndicatorLabel?.snp.makeConstraints { make in
            make.edges.equalToSuperview().offset(-5)
        }
        
        videoTimeLabel = UILabel()
        videoTimeLabel?.textColor = .white
        videoTimeLabel?.textAlignment = .center
        videoTimeLabel?.isUserInteractionEnabled = false
        videoTimeLabel?.font = UIFont.systemFont(ofSize: 12)
        videoTimeLabel?.isHidden = true
        view.addSubview(videoTimeLabel!)
        videoTimeLabel?.snp.makeConstraints { make in
            make.top.equalTo(captureButton!.snp.bottom).offset(5)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    private func initializeVideoTimer() {
        originalDate = Date()
        videoTimeLabel?.text = "00.00"
        self.videoTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector:#selector(self.getCurrentTime) , userInfo: nil, repeats: true)
    }
    
    @objc private func getCurrentTime() {
        guard let original = originalDate else {return}
        let now = Date()
        let minutes = Calendar.current.dateComponents([.minute], from: original, to: now).minute
        let seconds = Calendar.current.dateComponents([.second], from: original, to: now).second
        videoTimeLabel?.text = String(format:"%02d:%02d", (minutes ?? 0), (seconds ?? 0))
    }
    
    private func configCaptureButton() {
        captureButton?.setImage(captureIcon, for: .normal)
        captureButton?.addTarget(self, action: #selector(captureButtonClicked(_:)), for: .touchUpInside)
    }
    
    private func cameraIsCapturing() -> Bool {
        // Check if the camera is capturing
        return session?.cameraState(channel: 0)?.value.isCapturing == true
    }
    
    @objc func captureButtonClicked (_ sender:UIButton) {
        // If camera is capturing then add stop capture command else add start capture command
        captureButton?.isEnabled = false
        
        var cmd: KernelCommand
        
        if cameraIsCapturing() {
            cmd = Kernel.StopCaptureCameraCommand()
            self.stopCameraCaptureCommand = cmd as! Kernel.StopCaptureCameraCommand
        } else {
            cmd = Kernel.StartCaptureCameraCommand()
            self.startCameraCaptureCommand = cmd as! Kernel.StartCaptureCameraCommand
            
            if session?.cameraState(channel: 0)?.value.mode == .photo {
                activityIndicator?.startAnimating()
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
                captureModeImageView?.isHidden = false
                captureModeImageView?.image = modeImage
            } else {
                captureModeImageView?.isHidden = true
            }
            
            if count != "" {
                countIndicatorLabel?.isHidden = false
                countIndicatorLabel?.text = count
            } else {
                countIndicatorLabel?.isHidden = true
            }
        } else {
            captureModeImageView?.isHidden = true
            countIndicatorLabel?.isHidden = true
        }
    }
    
    @objc public override func update() {
        super.update()
        captureButton?.tintColor = (session?.cameraState(channel: 0)?.value.mode == .photo) ? .white : .red
        guard let photoMode = (session?.cameraState(channel: 0)?.value.photoMode) else {return}
        configCaptureModeImage(mode: photoMode)
    }
    
    public override func onCommandFinished(session: DroneSession, command: KernelCommand, error: Error?) {
        
        super.onCommandFinished(session: session, command: command, error: error)
        
        if let startCameraCommand = self.startCameraCaptureCommand {
            self.startCameraCaptureCommand = nil
            DispatchQueue.main.async {
                self.captureButton?.isEnabled = (command.id == startCameraCommand.id)
                
                guard let mode = (session.cameraState(channel: 0)?.value.mode) else {return}
                
                if mode == .video && error == nil {
                    
                    self.initializeVideoTimer()
                    self.videoTimeLabel?.isHidden = false
                    self.captureButton?.setImage(self.stopIcon, for: .normal)
                    
                } else if mode == .photo {
                    
                    self.activityIndicator?.stopAnimating()
                    AudioServicesPlaySystemSound(1108)
                }
                
            }
        } else if let stopCameraCommand = self.stopCameraCaptureCommand {
            self.stopCameraCaptureCommand = nil
            DispatchQueue.main.async {
                self.captureButton?.isEnabled = (command.id == stopCameraCommand.id)
                
                guard let mode = (session.cameraState(channel: 0)?.value.mode) else {return}
                
                if mode == .video && error == nil {
                    self.videoTimer?.invalidate()
                    self.videoTimer = nil
                    self.videoTimeLabel?.isHidden = true
                    self.captureButton?.setImage(self.captureIcon, for: .normal)
                }
            }
        }
      }
}
