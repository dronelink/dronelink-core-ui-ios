//
//  MissionViewController.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 4/18/19.
//  Copyright © 2019 Dronelink. All rights reserved.
//
import DronelinkCore
import Foundation
import UIKit
import SnapKit
import MaterialComponents.MaterialPalettes
import MaterialComponents.MaterialButtons
import MaterialComponents.MaterialProgressView

public protocol MissionViewControllerDelegate {
    func onExpandToggle()
}

public class MissionViewController: UIViewController {
    public static func create(droneSessionManager: DroneSessionManager, delegate: MissionViewControllerDelegate? = nil) -> MissionViewController {
        let missionViewController = MissionViewController()
        missionViewController.droneSessionManager = droneSessionManager
        missionViewController.delegate = delegate
        return missionViewController
    }
    
    private var delegate: MissionViewControllerDelegate?
    private var droneSessionManager: DroneSessionManager!
    private var session: DroneSession?
    private var missionExecutor: MissionExecutor?
    private var engaging = false
    private let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let primaryButton = MDCFloatingButton()
    private let expandToggleButton = UIButton()
    private let countdownProgressView = MDCProgressView()
    private let titleLabel = UILabel()
    private let timeElapsedLabel = UILabel()
    private let timeRemainingLabel = UILabel()
    private let progressView = MDCProgressView()
    private let messagesTextView = UITextView()
    private let dismissButton = UIButton(type: .custom)
    private var countdownTimer: Timer?
    private var countdownRemaining = 0
    private var countdownMax = 60
    private let updateInterval: TimeInterval = 0.5
    private var lastUpdated = Date()
    private let primaryEngagedColor = MDCPalette.pink.accent400
    private let primaryDisengagedColor = MDCPalette.deepPurple.tint800
    private let progressEngagedColor = MDCPalette.pink.accent400
    private let progressDisengagedColor = MDCPalette.deepPurple.accent200
    private let cancelImage = DronelinkUI.loadImage(named: "baseline_close_white_36pt")
    private let engageImage = DronelinkUI.loadImage(named: "baseline_play_arrow_white_36pt")
    private let disengageImage = DronelinkUI.loadImage(named: "baseline_pause_white_36pt")
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.layer.cornerRadius = DronelinkUI.Constants.cornerRadius
        blurEffectView.clipsToBounds = true
        view.addSubview(blurEffectView)
        
        view.addShadow()
        view.layer.cornerRadius = DronelinkUI.Constants.cornerRadius
        
        countdownProgressView.trackTintColor = UIColor.white.withAlphaComponent(0.75)
        countdownProgressView.isHidden = true
        view.addSubview(countdownProgressView)
        
        primaryButton.tintColor = UIColor.white
        primaryButton.addTarget(self, action: #selector(onPrimary(sender:)), for: .touchUpInside)
        view.addSubview(primaryButton)
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textColor = UIColor.white
        view.addSubview(titleLabel)
        
        timeElapsedLabel.font = timeElapsedLabel.font.withSize(15)
        timeElapsedLabel.textColor = titleLabel.textColor
        view.addSubview(timeElapsedLabel)
        
        timeRemainingLabel.textAlignment = .right
        timeRemainingLabel.font = timeElapsedLabel.font
        timeRemainingLabel.textColor = timeElapsedLabel.textColor
        timeRemainingLabel.text = timeElapsedLabel.text
        view.addSubview(timeRemainingLabel)
        
        progressView.trackTintColor = UIColor.white.withAlphaComponent(0.75)
        view.addSubview(progressView)
        
        messagesTextView.backgroundColor = UIColor.clear
        messagesTextView.font = UIFont.systemFont(ofSize: 12)
        messagesTextView.textColor = UIColor.white
        messagesTextView.isScrollEnabled = true
        messagesTextView.isEditable = false
        view.addSubview(messagesTextView)
        
        expandToggleButton.addTarget(self, action: #selector(onExpandToggle), for: .touchUpInside)
        view.addSubview(expandToggleButton)
        
        dismissButton.tintColor = UIColor.white
        dismissButton.setImage(DronelinkUI.loadImage(named: "baseline_close_white_36pt"), for: .normal)
        dismissButton.addTarget(self, action: #selector(onDismiss), for: .touchUpInside)
        view.addSubview(dismissButton)
        
        update()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Dronelink.shared.add(delegate: self)
        droneSessionManager.add(delegate: self)
        update()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Dronelink.shared.remove(delegate: self)
        droneSessionManager.remove(delegate: self)
        missionExecutor?.remove(delegate: self)
    }
    
    public override func updateViewConstraints() {
        super.updateViewConstraints()
        
        let defaultPadding = 10
        let labelHeight = 30
        
        blurEffectView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        primaryButton.isEnabled = session != nil
        primaryButton.snp.remakeConstraints { make in
            make.height.equalTo(60)
            make.width.equalTo(primaryButton.snp.height)
            make.top.equalToSuperview().offset(defaultPadding)
            make.left.equalToSuperview().offset(15)
        }
        
        countdownProgressView.snp.remakeConstraints { make in
            make.left.equalTo(primaryButton.snp.right).offset(defaultPadding)
            make.right.equalToSuperview().offset(-15)
            make.height.equalTo(4)
            make.centerY.equalTo(progressView.snp.centerY)
        }
        
        expandToggleButton.snp.remakeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalTo(titleLabel.snp.left)
            make.right.equalTo(titleLabel.snp.right)
            make.bottom.equalTo(timeElapsedLabel.snp.bottom)
        }
        
        titleLabel.snp.remakeConstraints { make in
            make.height.equalTo(labelHeight)
            make.left.equalTo(primaryButton.snp.right).offset(defaultPadding)
            make.right.equalTo(dismissButton.snp.left).offset(-defaultPadding)
            make.top.equalTo(primaryButton.snp.top)
        }
        
        timeElapsedLabel.snp.remakeConstraints { make in
            make.height.equalTo(labelHeight)
            make.width.equalTo(timeElapsedLabel.snp.height).multipliedBy(1.75)
            make.left.equalTo(titleLabel.snp.left)
            make.top.equalTo(titleLabel.snp.bottom)
        }
        
        timeRemainingLabel.snp.remakeConstraints { make in
            make.height.equalTo(timeElapsedLabel.snp.height)
            make.width.equalTo(timeElapsedLabel.snp.width)
            make.right.equalToSuperview().offset(-15)
            make.top.equalTo(timeElapsedLabel.snp.top)
        }
        
        progressView.snp.remakeConstraints { make in
            make.left.equalTo(timeElapsedLabel.snp.right)
            make.right.equalTo(timeRemainingLabel.snp.left)
            make.height.equalTo(4)
            make.centerY.equalTo(timeElapsedLabel.snp.centerY)
        }
        
        messagesTextView.snp.remakeConstraints { make in
            make.top.equalTo(90)
            make.left.equalToSuperview().offset(defaultPadding * 3)
            make.right.equalToSuperview().offset(-defaultPadding)
            make.bottom.equalToSuperview().offset(-defaultPadding)
        }
        
        dismissButton.snp.remakeConstraints { make in
            make.height.equalTo(24)
            make.width.equalTo(dismissButton.snp.height)
            make.top.equalToSuperview().offset(defaultPadding)
            make.right.equalToSuperview().offset(-defaultPadding)
        }
    }
    
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        view.setNeedsUpdateConstraints()
    }
    
    @objc func onPrimary(sender: Any) {
        guard let missionExecutor = missionExecutor else { return }
        
        if (engaging || missionExecutor.engaged) {
            missionExecutor.disengage(reason: Mission.Message(title: "MissionDisengageReason.user.disengaged".localized))
            return
        }
        
        if countdownTimer != nil {
            stopCountdown()
            return
        }
        
        if let session = session {
            if let engageDisallowedReasons = missionExecutor.engageDisallowedReasons(droneSession: session), engageDisallowedReasons.count > 0 {
                let reason = engageDisallowedReasons.first!
                DronelinkUI.shared.showDialog(title: reason.title, details: reason.details)
            }
            else {
                DispatchQueue.main.async {
                    self.startCountdown()
                }
            }
        }
        
    }
    
    private func startCountdown() {
        countdownRemaining = countdownMax
        Dronelink.shared.announce(message: "\(countdownRemaining / 20)")
        countdownProgressView.setHidden(false, animated: true)
        progressView.setHidden(true, animated: true)
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            guard
                let missionExecutor = self.missionExecutor,
                let session = self.session
            else {
                self.stopCountdown()
                return
            }
            
            self.countdownRemaining -= 1
            if (self.countdownRemaining == 0) {
                self.engaging = true
                self.stopCountdown(aborted: false)
                do {
                    try missionExecutor.engage(droneSession: session)
                }
                catch MissionExecutorError.droneSerialNumberUnavailable {
                    DronelinkUI.shared.showDialog(title: "MissionViewController.start.engage.droneSerialNumberUnavailable.title".localized, details: "MissionViewController.start.engage.droneSerialNumberUnavailable.message".localized)
                }
                catch {
                }
            }
            else {
                self.update()
                if (self.countdownRemaining % 20 == 0) {
                    Dronelink.shared.announce(message: "\(self.countdownRemaining / 20)")
                }
            }
        }
        update()
    }
    
    private func stopCountdown(aborted: Bool = true) {
        countdownProgressView.setHidden(true, animated: true)
        progressView.setHidden(false, animated: true)
        countdownTimer?.invalidate()
        countdownTimer = nil
        update()
        if (aborted) {
            Dronelink.shared.announce(message: "MissionViewController.start.cancelled".localized)
        }
    }
    
    @objc func onExpandToggle() {
        delegate?.onExpandToggle()
    }
    
    @objc func onDismiss() {
        Dronelink.shared.unloadMission()
    }
    
    func update() {
        timeElapsedLabel.isHidden = countdownTimer != nil
        timeRemainingLabel.isHidden = timeElapsedLabel.isHidden
        
        if countdownTimer != nil {
            titleLabel.text = String(format: "MissionViewController.start.countdown".localized, Int(ceil(Double(countdownRemaining) / 20)))
            timeElapsedLabel.text = NumberFormatter.localizedString(from: countdownRemaining as NSNumber, number: .decimal)
            timeRemainingLabel.text = nil
            let progress = Float(countdownMax - countdownRemaining) / Float(countdownMax)
            countdownProgressView.setProgress(progress, animated: true)
            countdownProgressView.progressTintColor = progressDisengagedColor?.interpolate(progressEngagedColor, percent: CGFloat(progress))
            messagesTextView.text = nil
            primaryButton.setBackgroundColor(primaryDisengagedColor.interpolate(primaryEngagedColor, percent: CGFloat(progress)))
            primaryButton.setImage(cancelImage, for: .normal)
            dismissButton.isHidden = true
            return
        }
        
        let engaged = engaging || missionExecutor?.engaged ?? false
        let totalTime = missionExecutor?.estimateTotalTime() ?? 0
        let timeElapsed = missionExecutor?.componentExecutionDuration() ?? 0
        let timeRemaining = max(totalTime - timeElapsed, 0)
        timeElapsedLabel.text = missionExecutor?.format(formatter: "timeElapsed", value: timeElapsed, defaultValue: "MissionViewController.timeElapsed.empty".localized)
        timeRemainingLabel.text = missionExecutor?.format(formatter: "timeElapsed", value: timeRemaining, defaultValue: "MissionViewController.timeElapsed.empty".localized)
        progressView.setProgress(Float(min(totalTime == 0 ? 0 : timeElapsed / totalTime, 1)), animated: true)
        progressView.progressTintColor = engaged ? progressEngagedColor: progressDisengagedColor
        messagesTextView.text = missionExecutor?.engaged ?? false ? missionExecutor?.executingMessageGroups.map({
            return $0.display
        }).joined(separator: "\n\n") : nil
        
        primaryButton.setBackgroundColor(engaged ? primaryEngagedColor : primaryDisengagedColor)
        primaryButton.setImage(engaged ? disengageImage : engageImage, for: .normal)
        dismissButton.isHidden = engaged
        countdownProgressView.progress = 0
        titleLabel.text = engaging ? "MissionViewController.start.engaging".localized : missionExecutor?.missionDescriptors.display
    }
}

extension MissionViewController: DronelinkDelegate {
    public func onRegistered(error: String?) {}
    
    public func onMissionLoaded(executor: MissionExecutor) {
        missionExecutor = executor
        executor.add(delegate: self)
        DispatchQueue.main.async {
            self.view.setNeedsUpdateConstraints()
        }
    }
    
    public func onMissionUnloaded(executor: MissionExecutor) {
        missionExecutor = nil
        executor.remove(delegate: self)
        DispatchQueue.main.async {
            self.view.setNeedsUpdateConstraints()
        }
    }
}

extension MissionViewController: DroneSessionManagerDelegate {
    public func onOpened(session: DroneSession) {
        self.session = session
        DispatchQueue.main.async {
            self.view.setNeedsUpdateConstraints()
        }
        
        //delay to give the aircraft time to report location
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            self.missionExecutor?.estimate(droneSession: session)
        }
    }
    
    public func onClosed(session: DroneSession) {
        self.session = nil
        DispatchQueue.main.async {
            self.view.setNeedsUpdateConstraints()
        }
    }
}

extension MissionViewController: MissionExecutorDelegate {
    public func onMissionEstimated(executor: MissionExecutor, duration: TimeInterval) {
        DispatchQueue.main.async {
            self.update()
        }
    }
    
    public func onMissionEngaged(executor: MissionExecutor, engagement: MissionExecutor.Engagement) {
        DispatchQueue.main.async {
            self.update()
        }
    }
    
    public func onMissionExecuted(executor: MissionExecutor, engagement: MissionExecutor.Engagement) {
        engaging = false
        if (-lastUpdated.timeIntervalSinceNow >= updateInterval) {
            lastUpdated = Date()
            DispatchQueue.main.async {
                self.update()
            }
        }
    }
    
    public func onMissionDisengaged(executor: MissionExecutor, engagement: MissionExecutor.Engagement, reason: Mission.Message) {
        engaging = false
        DispatchQueue.main.async {
            self.update()
        }
    }
}
