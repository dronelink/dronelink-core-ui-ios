//
//  MissionViewController.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 4/18/19.
//  Copyright © 2019 Dronelink. All rights reserved.
//
import DronelinkCore
import Foundation
import CoreLocation
import UIKit
import SnapKit
import Agrume
import MaterialComponents.MaterialPalettes
import MaterialComponents.MaterialButtons
import MaterialComponents.MaterialProgressView
import MaterialComponents.MDCActivityIndicator

public protocol MissionViewControllerDelegate {
    func onMissionExpandToggle()
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
    
    private let activityIndicator = MDCActivityIndicator()
    private let primaryButton = MDCFloatingButton()
    private let expandToggleButton = UIButton()
    private let countdownProgressView = MDCProgressView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let executionDurationLabel = UILabel()
    private let timeRemainingLabel = UILabel()
    private let progressView = MDCProgressView()
    private let messagesTextView = UITextView()
    private let dismissButton = UIButton(type: .custom)
    
    private let primaryEngagedColor = DronelinkUI.Constants.secondaryColor
    private let primaryDisengagedColor = DronelinkUI.Constants.primaryColor
    private let progressEngagedColor = MDCPalette.pink.accent400
    private let progressDisengagedColor = MDCPalette.deepPurple.accent200
    private let cancelImage = DronelinkUI.loadImage(named: "baseline_close_white_36pt")
    private let engageImage = DronelinkUI.loadImage(named: "baseline_play_arrow_white_36pt")
    private let disengageImage = DronelinkUI.loadImage(named: "baseline_pause_white_36pt")
    
    private var previousEstimateContext: (coordinate: CLLocationCoordinate2D, altitude: Double)?
    private var engageOnMissionEstimated = false
    private var countdownTimer: Timer?
    private var countdownRemaining = 0
    private var countdownMax = 60
    private let updateInterval: TimeInterval = 0.5
    private var lastUpdated = Date()
    private var _expanded = false
    public var expanded: Bool { _expanded }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addShadow()
        view.layer.cornerRadius = DronelinkUI.Constants.cornerRadius
        view.backgroundColor = DronelinkUI.Constants.overlayColor
        
        countdownProgressView.trackTintColor = UIColor.white.withAlphaComponent(0.75)
        countdownProgressView.isHidden = true
        view.addSubview(countdownProgressView)

        activityIndicator.radius = 20
        activityIndicator.strokeWidth = 5
        activityIndicator.cycleColors = [progressEngagedColor!]
        view.addSubview(activityIndicator)
        
        primaryButton.tintColor = UIColor.white
        primaryButton.addTarget(self, action: #selector(onPrimary(sender:)), for: .touchUpInside)
        view.addSubview(primaryButton)
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.minimumScaleFactor = 0.5
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.textColor = UIColor.white
        view.addSubview(titleLabel)
        
        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
        subtitleLabel.minimumScaleFactor = 0.5
        subtitleLabel.adjustsFontSizeToFitWidth = true
        subtitleLabel.textColor = UIColor.white
        view.addSubview(subtitleLabel)
        
        executionDurationLabel.font = executionDurationLabel.font.withSize(15)
        executionDurationLabel.textColor = titleLabel.textColor
        executionDurationLabel.minimumScaleFactor = 0.5
        executionDurationLabel.adjustsFontSizeToFitWidth = true
        view.addSubview(executionDurationLabel)
        
        timeRemainingLabel.textAlignment = .right
        timeRemainingLabel.font = executionDurationLabel.font
        timeRemainingLabel.textColor = executionDurationLabel.textColor
        timeRemainingLabel.text = executionDurationLabel.text
        timeRemainingLabel.minimumScaleFactor = 0.5
        timeRemainingLabel.adjustsFontSizeToFitWidth = true
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
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        droneSessionManager.add(delegate: self)
        Dronelink.shared.add(delegate: self)
        update()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        droneSessionManager.remove(delegate: self)
        Dronelink.shared.remove(delegate: self)
        missionExecutor?.remove(delegate: self)
    }
    
    public override func updateViewConstraints() {
        super.updateViewConstraints()
        
        let defaultPadding = 10
        let labelHeight = 30
        
        primaryButton.snp.remakeConstraints { make in
            make.height.equalTo(60)
            make.width.equalTo(primaryButton.snp.height)
            make.top.equalToSuperview().offset(defaultPadding)
            make.left.equalToSuperview().offset(15)
        }
        
        activityIndicator.snp.remakeConstraints { make in
            make.edges.equalTo(primaryButton)
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
            make.bottom.equalTo(executionDurationLabel.snp.bottom)
        }
        
        titleLabel.snp.remakeConstraints { make in
            make.height.equalTo(labelHeight)
            make.left.equalTo(primaryButton.snp.right).offset(defaultPadding)
            make.right.equalTo(dismissButton.snp.left).offset(-defaultPadding)
            make.top.equalTo(primaryButton.snp.top)
        }
        
        subtitleLabel.snp.remakeConstraints { make in
            make.height.equalTo(labelHeight)
            make.left.equalTo(titleLabel.snp.left)
            make.right.equalTo(titleLabel.snp.right)
            make.top.equalTo(titleLabel.snp.bottom)
        }
        
        executionDurationLabel.snp.remakeConstraints { make in
            make.height.equalTo(labelHeight)
            make.width.equalTo(executionDurationLabel.snp.height).multipliedBy(1.75)
            make.left.equalTo(titleLabel.snp.left)
            make.top.equalTo(titleLabel.snp.bottom)
        }
        
        timeRemainingLabel.snp.remakeConstraints { make in
            make.height.equalTo(executionDurationLabel.snp.height)
            make.width.equalTo(executionDurationLabel.snp.width)
            make.right.equalToSuperview().offset(-15)
            make.top.equalTo(executionDurationLabel.snp.top)
        }
        
        progressView.snp.remakeConstraints { make in
            make.left.equalTo(executionDurationLabel.snp.right)
            make.right.equalTo(timeRemainingLabel.snp.left)
            make.height.equalTo(4)
            make.centerY.equalTo(executionDurationLabel.snp.centerY)
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
        
        if countdownTimer != nil {
            stopCountdown()
            return
        }
        
        if missionExecutor.engaged {
            missionExecutor.disengage(reason: Kernel.Message(title: "MissionDisengageReason.user.disengaged".localized))
            return
        }

        guard let session = session else {
            return
        }
        
        if let engageDisallowedReasons = missionExecutor.engageDisallowedReasons(droneSession: session), engageDisallowedReasons.count > 0 {
            let reason = engageDisallowedReasons.first!
            DronelinkUI.shared.showDialog(title: reason.title, details: reason.details)
            return
        }
        
        promptConfirmation()
    }
    
    private func promptConfirmation() {
        guard let missionExecutor = missionExecutor else { return }
        
        if missionExecutor.engagementCount > 0,
            let confirmationMessage = missionExecutor.reengagementRules.confirmationMessage {
            var actions = [
                MDCAlertAction(title: "resume".localized, emphasis: .high, handler: { action in
                    self.promptTakeoffLocationWarning()
                }),
                MDCAlertAction(title: "cancel".localized, emphasis: .medium, handler: { action in
                })
            ]
            
            if let confirmationInstructionsImageUrl = missionExecutor.reengagementRules.confirmationInstructionsImageUrl {
                actions.append(MDCAlertAction(title: "learnMore".localized, emphasis: .low, handler: { action in
                    let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
                    doneButton.tintColor = .white
                    let agrume = Agrume(
                        url: URL(string: confirmationInstructionsImageUrl)!,
                        background: .blurred(.dark),
                        dismissal: .withButton(doneButton))
                    agrume.statusBarStyle = .lightContent
                    agrume.show(from: self)
                }))
            }
            
            DronelinkUI.shared.showDialog(
                title: confirmationMessage.title,
                details: confirmationMessage.details,
                actions: actions)
            return
        }
        
        promptTakeoffLocationWarning()
    }
    
    private func promptTakeoffLocationWarning() {
        guard let missionExecutor = missionExecutor, let session = session else { return }
        
        missionExecutor.droneTakeoffAltitudeAlternate = nil
        if missionExecutor.requiredTakeoffArea == nil,
            let actualTakeoffLocation = session.state?.value.takeoffLocation,
            let suggestedTakeoffLocation = missionExecutor.takeoffCoordinate?.location,
            actualTakeoffLocation.distance(from: suggestedTakeoffLocation) > 50.convertFeetToMeters {
            if let deviceLocation = Dronelink.shared.locationManager.location, deviceLocation.verticalAccuracy >= 0 {
                missionExecutor.droneTakeoffAltitudeAlternate = deviceLocation.altitude
            }

            let distance = Dronelink.shared.format(formatter: "distance", value: actualTakeoffLocation.distance(from: suggestedTakeoffLocation))
            let altitude = missionExecutor.droneTakeoffAltitudeAlternate == nil ? nil : Dronelink.shared.format(formatter: "altitude", value: missionExecutor.droneTakeoffAltitudeAlternate!)
            DronelinkUI.shared.showDialog(
                title: "MissionViewController.start.takeoffLocationWarning.title".localized,
                details: altitude != nil && missionExecutor.elevationsRequired
                    ? String(format: "MissionViewController.start.takeoffLocationWarning.message.device.altitude.available".localized, distance, altitude!)
                    : String(format: "MissionViewController.start.takeoffLocationWarning.message.device.altitude.unavailable".localized, distance),
                actions: [
                    MDCAlertAction(title: "continue".localized, emphasis: .high, handler: { action in
                        self.startCountdown()
                    }),
                    MDCAlertAction(title: "cancel".localized, emphasis: .low, handler: { action in
                    })
                ])
            return
        }
        
        startCountdown()
    }
    
    private func startCountdown() {
        countdownRemaining = countdownMax
        Dronelink.shared.announce(message: "\(countdownRemaining / 20)")
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            guard
                let _ = self.missionExecutor,
                let _ = self.session
            else {
                self.stopCountdown()
                return
            }
            
            self.countdownRemaining -= 1
            if (self.countdownRemaining == 0) {
                self.stopCountdown(aborted: false)
                self.engageOnMissionEstimated = true
                if !self.estimateMission() {
                    self.engage()
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
        countdownTimer?.invalidate()
        countdownTimer = nil
        update()
        if (aborted) {
            Dronelink.shared.announce(message: "MissionViewController.start.cancelled".localized)
        }
    }
    
    private func engage() {
        engageOnMissionEstimated = false
        DispatchQueue.main.async {
            guard
                let missionExecutor = self.missionExecutor,
                let session = self.session
            else {
                return
            }

            do {
                try missionExecutor.engage(droneSession: session) { disallowed in
                    DronelinkUI.shared.showDialog(title: disallowed.title, details: disallowed.details)
                    DispatchQueue.main.async {
                        self.update()
                    }
                }
            }
            catch DronelinkError.droneSerialNumberUnavailable {
                DronelinkUI.shared.showDialog(title: "MissionViewController.start.engage.droneSerialNumberUnavailable.title".localized, details: "MissionViewController.start.engage.droneSerialNumberUnavailable.message".localized)
                self.update()
            }
            catch {
                self.update()
            }
        }
    }
    
    @objc func onExpandToggle() {
        toggle(expanded: !expanded)
    }
    
    public func toggle(expanded: Bool) {
        _expanded = expanded
        delegate?.onMissionExpandToggle()
    }
    
    @objc func onDismiss() {
        Dronelink.shared.unloadMission()
    }
    
    func update() {
        guard let missionExecutor = missionExecutor else {
            return
        }

        titleLabel.text = missionExecutor.descriptors.display

        if missionExecutor.estimating {
            activityIndicator.isHidden = false
            primaryButton.isHidden = true
            subtitleLabel.isHidden = false
            executionDurationLabel.isHidden = true
            timeRemainingLabel.isHidden = true
            progressView.isHidden = true
            countdownProgressView.isHidden = true
            dismissButton.isHidden = false
            messagesTextView.isHidden = true

            activityIndicator.startAnimating()
            subtitleLabel.text = "MissionViewController.estimating".localized
            return
        }

        if countdownTimer != nil {
            activityIndicator.isHidden = true
            primaryButton.isHidden = false
            subtitleLabel.isHidden = true
            executionDurationLabel.isHidden = true
            timeRemainingLabel.isHidden = true
            progressView.isHidden = true
            countdownProgressView.isHidden = false
            dismissButton.isHidden = false
            messagesTextView.isHidden = true

            activityIndicator.stopAnimating()
            let progress = Float(countdownMax - countdownRemaining) / Float(countdownMax)
            primaryButton.isEnabled = true
            primaryButton.setBackgroundColor(primaryDisengagedColor.interpolate(primaryEngagedColor, percent: CGFloat(progress)))
            primaryButton.setImage(cancelImage, for: .normal)
            titleLabel.text = String(format: "MissionViewController.start.countdown".localized, Int(ceil(Double(countdownRemaining) / 20)))
            countdownProgressView.setProgress(progress, animated: true)
            countdownProgressView.progressTintColor = progressDisengagedColor?.interpolate(progressEngagedColor, percent: CGFloat(progress))
            return
        }

        if missionExecutor.engaging {
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
            primaryButton.isHidden = true
            subtitleLabel.isHidden = false
            executionDurationLabel.isHidden = true
            timeRemainingLabel.isHidden = true
            progressView.isHidden = true
            countdownProgressView.isHidden = true
            dismissButton.isHidden = true
            messagesTextView.isHidden = true

            subtitleLabel.text = "MissionViewController.start.engaging".localized
            return
        }

        activityIndicator.isHidden = true
        primaryButton.isHidden = false
        subtitleLabel.isHidden = true
        executionDurationLabel.isHidden = false
        timeRemainingLabel.isHidden = false
        progressView.isHidden = false
        countdownProgressView.isHidden = true
        dismissButton.isHidden = missionExecutor.engaged
        messagesTextView.isHidden = false

        activityIndicator.stopAnimating()
        primaryButton.isEnabled = session != nil
        var estimateTime = 0.0
        var executionDuration = 0.0
        if let estimate = missionExecutor.estimate {
            estimateTime = estimate.time
            executionDuration = missionExecutor.executionDuration
        }
        let timeRemaining = max(estimateTime - executionDuration, 0)
        executionDurationLabel.text = Dronelink.shared.format(formatter: "timeElapsed", value: executionDuration, defaultValue: "MissionViewController.executionDuration.empty".localized)
        timeRemainingLabel.text = Dronelink.shared.format(formatter: "timeElapsed", value: timeRemaining, defaultValue: "MissionViewController.executionDuration.empty".localized)
        progressView.setProgress(Float(min(estimateTime == 0 ? 0 : executionDuration / estimateTime, 1)), animated: true)

        if missionExecutor.engaged {
            progressView.progressTintColor = progressEngagedColor
            messagesTextView.text = expanded ? missionExecutor.executingMessageGroups.map({ $0.display }).joined(separator: "\n\n") : nil
            primaryButton.setBackgroundColor(primaryEngagedColor)
            primaryButton.setImage(disengageImage, for: .normal)
        }
        else {
            progressView.progressTintColor = progressDisengagedColor
            messagesTextView.text = nil
            primaryButton.setBackgroundColor(primaryDisengagedColor)
            primaryButton.setImage(engageImage, for: .normal)
        }
    }
    
    @discardableResult
    func estimateMission() -> Bool {
        guard let missionExecutor = missionExecutor, !missionExecutor.estimating else {
            return false
        }
        
        let estimateContext = (coordinate: session?.state?.value.location?.coordinate ?? CLLocationCoordinate2D(), altitude: session?.state?.value.altitude ?? 0)
        if let previousEstimateContext = previousEstimateContext {
            if previousEstimateContext.coordinate.distance(to: estimateContext.coordinate) < 1 && abs(previousEstimateContext.altitude - estimateContext.altitude) < 1 {
                return false
            }
        }
        
        previousEstimateContext = estimateContext
        missionExecutor.estimate(droneSession: self.session, altitudeRequired: true, timeRequired: true)
        return true
    }
}

extension MissionViewController: DronelinkDelegate {
    public func onRegistered(error: String?) {}
    
    public func onMissionLoaded(executor: MissionExecutor) {
        missionExecutor = executor
        previousEstimateContext = nil
        executor.add(delegate: self)
        estimateMission()
        
        DispatchQueue.main.async {
            self.view.setNeedsUpdateConstraints()
            self.update()
            
            if let missionDetailsExpanded = executor.userInterfaceSettings?.missionDetailsExpanded {
                self.toggle(expanded: missionDetailsExpanded)
            }
        }
    }
    
    public func onMissionUnloaded(executor: MissionExecutor) {
        missionExecutor = nil
        previousEstimateContext = nil
        executor.remove(delegate: self)
        DispatchQueue.main.async {
            self.view.setNeedsUpdateConstraints()
            self.update()
        }
    }
    
    public func onFuncLoaded(executor: FuncExecutor) {}
    
    public func onFuncUnloaded(executor: FuncExecutor) {}
}

extension MissionViewController: DroneSessionManagerDelegate {
    public func onOpened(session: DroneSession) {
        self.session = session
        session.add(delegate: self)
        DispatchQueue.main.async {
            self.view.setNeedsUpdateConstraints()
            self.update()
        }
    }
    
    public func onClosed(session: DroneSession) {
        self.session = nil
        session.remove(delegate: self)
        DispatchQueue.main.async {
            self.view.setNeedsUpdateConstraints()
            self.update()
        }
    }
}

extension MissionViewController: DroneSessionDelegate {
    public func onInitialized(session: DroneSession) {}
    
    public func onLocated(session: DroneSession) {
        estimateMission()
    }
    
    public func onMotorsChanged(session: DroneSession, value: Bool) {}
    
    public func onCommandExecuted(session: DroneSession, command: KernelCommand) {}
    
    public func onCommandFinished(session: DroneSession, command: KernelCommand, error: Error?) {}
    
    public func onCameraFileGenerated(session: DroneSession, file: CameraFile) {}
}

extension MissionViewController: MissionExecutorDelegate {
    public func onMissionEstimating(executor: MissionExecutor) {
        DispatchQueue.main.async {
            self.update()
        }
    }
    
    public func onMissionEstimated(executor: MissionExecutor, estimate: MissionExecutor.Estimate) {
        if self.engageOnMissionEstimated {
            self.engage()
            return
        }

        DispatchQueue.main.async {
            self.update()
        }
    }
    
    public func onMissionEngaging(executor: MissionExecutor) {
        Dronelink.shared.announce(message: "MissionViewController.engaging".localized)
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
        if (-lastUpdated.timeIntervalSinceNow >= updateInterval) {
            lastUpdated = Date()
            DispatchQueue.main.async {
                self.update()
            }
        }
    }
    
    public func onMissionDisengaged(executor: MissionExecutor, engagement: MissionExecutor.Engagement, reason: Kernel.Message) {
        if (reason.title != "MissionDisengageReason.user.disengaged".localized) {
            DronelinkUI.shared.showDialog(title: reason.title, details: reason.details)
        }
        
        if executor.status.completed {
            Dronelink.shared.unloadMission()
            Dronelink.shared.announce(message: reason.title)
            return
        }

        Dronelink.shared.announce(message: "MissionViewController.disengaged".localized)
        DispatchQueue.main.async {
            self.update()
        }
    }
}
