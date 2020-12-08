//
//  CameraCaptureWidget.swift
//  DronelinkCoreUI
//
//  Created by Nicolas Torres on 3/12/20.
//  Copyright © 2020 Dronelink. All rights reserved.
//
import UIKit
import DronelinkCore
import MaterialComponents.MaterialPalettes
import MaterialComponents.MaterialButtons
import MaterialComponents.MaterialButtons_Theming
import MarqueeLabel

public class CameraCaptureWidget: UpdatableWidget {
    
    public var captureButton: UIButton?
    public var captureModeImageView: UIImageView?
    public var countIndicatorLabel: UILabel?
    
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        captureButton = UIButton()
        configCaptureButton()
        view.addSubview(captureButton!)
        captureButton?.snp.makeConstraints { make in
            make.edges.equalToSuperview()
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
        view.addSubview(countIndicatorLabel!)
        countIndicatorLabel?.textAlignment = .right
        countIndicatorLabel?.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func configCaptureButton() {
        captureButton?.setImage(DronelinkUI.loadImage(named: "captureIcon")?.withRenderingMode(.alwaysTemplate), for: .normal)
        captureButton?.addTarget(self, action: #selector(captureButtonClicked(_:)), for: .touchUpInside)
    }
    
    private func cameraIsCapturing() -> Bool {
        // Check if the camera is capturing
        return session?.cameraState(channel: 0)?.value.isCapturing == true
    }
    
    @objc func captureButtonClicked (_ sender:UIButton) {
        // If camera is capturing then add stop capture command else add start capture command
        try? self.session?.add(command: cameraIsCapturing() ? Kernel.StopCaptureCameraCommand() : Kernel.StartCaptureCameraCommand())
    }
    
    private func configCaptureModeImage(mode: DronelinkCore.Kernel.CameraPhotoMode?) {
        
        if session?.cameraState(channel: 0)?.value.mode == .photo {
            var imageName = ""
            var count = ""
            
            switch mode {
            case .aeb:
                imageName = "aebMode"
                if let aeb = session?.cameraState(channel: 0)?.value.aebCount {
                    count =  aeb.rawValue
                }
            case .burst:
                imageName = "burstMode"
                if let burst = session?.cameraState(channel: 0)?.value.burstCount {
                    count =  burst.rawValue
                }
            case .ehdr:
                imageName = "hdrMode"
            case .hyperLight:
                imageName = "hyperMode"
            case .interval:
                imageName = "timerMode"
                if let interval = session?.cameraState(channel: 0)?.value.photoInterval {
                    count =  String(interval)
                }
            case .panorama:
                imageName = "panoMode"
            default:
                imageName = ""
            }
            
            if imageName != "" {
                captureModeImageView?.isHidden = false
                captureModeImageView?.image = DronelinkUI.loadImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
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
}
