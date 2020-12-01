//
//  InstrumentsViewController.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 6/8/20.
//  Copyright © 2020 Dronelink. All rights reserved.
//

import Foundation
import UIKit
import DronelinkCore
import SnapKit

public class InstrumentsViewController: UIViewController {
    public static func create(droneSessionManager: DroneSessionManager) -> InstrumentsViewController {
        let instrumentsViewController = InstrumentsViewController()
        instrumentsViewController.droneSessionManager = droneSessionManager
        return instrumentsViewController
    }
    
    private var droneSessionManager: DroneSessionManager!
    private var session: DroneSession?
    
    private let gpsImageView = UIImageView()
    private let gpsLabel = UILabel()
    private let signalImageView = UIImageView()
    private let signalLabel = UILabel()
    private let batteryImageView = UIImageView()
    private let batteryLabel = UILabel()
    
    private let spacing: CGFloat = 2
    private let height: CGFloat = 30
    private let imageWidth: CGFloat = 30
    private let labelWidth: CGFloat = 50
    
    private let updateInterval: TimeInterval = 0.5
    private var updateTimer: Timer?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        gpsImageView.image = DronelinkUI.loadImage(named: "satellite-variant")
        gpsImageView.tintColor = UIColor.white
        view.addSubview(gpsImageView)
        gpsImageView.snp.makeConstraints { make in
            make.width.equalTo(imageWidth)
            make.height.equalTo(height)
        }
        
        gpsLabel.textColor = UIColor.white
        gpsLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        view.addSubview(gpsLabel)
        gpsLabel.snp.makeConstraints { make in
            make.left.equalTo(gpsImageView.snp.right).offset(spacing)
            make.width.equalTo(35)
            make.height.equalTo(height)
        }
        
        signalImageView.image = DronelinkUI.loadImage(named: "baseline_signal_cellular_alt_white_36pt")
        signalImageView.tintColor = UIColor.white
        view.addSubview(signalImageView)
        signalImageView.snp.makeConstraints { make in
            make.left.equalTo(gpsLabel.snp.right).offset(spacing)
            make.width.equalTo(imageWidth)
            make.height.equalTo(height)
        }
        
        signalLabel.textColor = UIColor.white
        signalLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        view.addSubview(signalLabel)
        signalLabel.snp.makeConstraints { make in
            make.left.equalTo(signalImageView.snp.right).offset(spacing)
            make.width.equalTo(labelWidth)
            make.height.equalTo(height)
        }
        
        batteryImageView.image = DronelinkUI.loadImage(named: "battery-high")
        batteryImageView.tintColor = UIColor.white
        view.addSubview(batteryImageView)
        batteryImageView.snp.makeConstraints { make in
            make.left.equalTo(signalLabel.snp.right).offset(spacing)
            make.width.equalTo(imageWidth)
            make.height.equalTo(height)
        }
        
        batteryLabel.textColor = UIColor.white
        batteryLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        view.addSubview(batteryLabel)
        batteryLabel.snp.makeConstraints { make in
            make.left.equalTo(batteryImageView.snp.right).offset(spacing)
            make.width.equalTo(labelWidth)
            make.height.equalTo(height)
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateTimer = Timer.scheduledTimer(timeInterval: updateInterval, target: self, selector: #selector(update), userInfo: nil, repeats: true)
        droneSessionManager.add(delegate: self)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        updateTimer?.invalidate()
        updateTimer = nil
        droneSessionManager.remove(delegate: self)
    }
    
    @objc func update() {
        if let gpsSatellites = session?.state?.value.gpsSatellites {
            gpsLabel.text = "\(gpsSatellites)"
        }
        else {
            gpsLabel.text = "InstrumentsViewController.empty".localized
        }
        signalLabel.text = Dronelink.shared.format(formatter: "percent", value: session?.state?.value.downlinkSignalStrength, defaultValue: "InstrumentsViewController.empty".localized)
        batteryLabel.text = Dronelink.shared.format(formatter: "percent", value: session?.state?.value.batteryPercent, defaultValue: "InstrumentsViewController.empty".localized)
    }
}

extension InstrumentsViewController: DroneSessionManagerDelegate {
    public func onOpened(session: DroneSession) {
        self.session = session
    }
    
    public func onClosed(session: DroneSession) {
        self.session = nil
    }
}
