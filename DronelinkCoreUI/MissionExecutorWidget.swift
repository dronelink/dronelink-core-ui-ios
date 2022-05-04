//
//  MissionExecutorWidget.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 12/7/20.
//  Copyright © 2020 Dronelink. All rights reserved.
//

import Foundation
import SafariServices
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

public class MissionExecutorWidget: UpdatableWidget, ExecutorWidget {
    public override var updateInterval: TimeInterval { 0.5 }
    
    public var layout: DynamicSizeWidgetLayout = .small
    
    public var preferredSize: CGSize {
        if (portrait && tablet) {
            return CGSize(width: 0, height: layout == .small ? 80 : 0)
        }
        
        if (portrait) {
            return CGSize(width: 0, height: layout == .small ? 100 : 80)
        }
        
        return CGSize(width: tablet ? 350 : 0, height: layout == .small ? 80 : (tablet ? 180 : 0))
    }
    
    private let activityIndicator = MDCActivityIndicator()
    private let primaryButton = MDCFloatingButton()
    private let layoutToggleButton = UIButton()
    private let countdownProgressView = MDCProgressView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let executionDurationLabel = UILabel()
    private let timeRemainingLabel = UILabel()
    private let progressView = MDCProgressView()
    private let detailsButton = MDCButton()
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
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addShadow()
        view.layer.cornerRadius = DronelinkUI.Constants.cornerRadius
        view.backgroundColor = DronelinkUI.Constants.overlayColor
        view.clipsToBounds = true
        
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
        messagesTextView.font = UIFont.boldSystemFont(ofSize: 14)
        messagesTextView.textColor = UIColor.white
        messagesTextView.isScrollEnabled = true
        messagesTextView.isEditable = false
        view.addSubview(messagesTextView)
        
        let scheme = MDCContainerScheme()
        scheme.colorScheme = MDCSemanticColorScheme(defaults: .materialDark201907)
        scheme.colorScheme.primaryColor = UIColor.white
        detailsButton.applyOutlinedTheme(withScheme: scheme)
        detailsButton.translatesAutoresizingMaskIntoConstraints = false
        detailsButton.setTitle("MissionExecutorWidget.details".localized, for: .normal)
        detailsButton.setTitleColor(UIColor.white, for: .normal)
        detailsButton.setBorderColor(UIColor.white.withAlphaComponent(0.75), for: .normal)
        detailsButton.setBorderColor(UIColor.white.withAlphaComponent(0.25), for: .disabled)
        detailsButton.addTarget(self, action: #selector(onDetails(sender:)), for: .touchUpInside)
        view.addSubview(detailsButton)
        
        layoutToggleButton.addTarget(self, action: #selector(onLayoutToggle), for: .touchUpInside)
        view.addSubview(layoutToggleButton)
        
        dismissButton.tintColor = UIColor.white
        dismissButton.setImage(DronelinkUI.loadImage(named: "baseline_close_white_36pt"), for: .normal)
        dismissButton.addTarget(self, action: #selector(onDismiss), for: .touchUpInside)
        view.addSubview(dismissButton)
    }
    
    public override func updateViewConstraints() {
        super.updateViewConstraints()
        
        let labelHeight = 30
        
        primaryButton.snp.remakeConstraints { [weak self] make in
            make.height.equalTo(60)
            make.width.equalTo(primaryButton.snp.height)
            make.top.equalToSuperview().offset(defaultPadding)
            make.left.equalToSuperview().offset(15)
        }
        
        activityIndicator.snp.remakeConstraints { [weak self] make in
            make.edges.equalTo(primaryButton)
        }
        
        countdownProgressView.snp.remakeConstraints { [weak self] make in
            make.left.equalTo(primaryButton.snp.right).offset(defaultPadding)
            make.right.equalToSuperview().offset(-15)
            make.height.equalTo(4)
            make.centerY.equalTo(progressView.snp.centerY)
        }
        
        layoutToggleButton.snp.remakeConstraints { [weak self] make in
            make.top.equalToSuperview()
            make.left.equalTo(titleLabel.snp.left)
            make.right.equalTo(titleLabel.snp.right)
            make.bottom.equalTo(executionDurationLabel.snp.bottom)
        }
        
        titleLabel.snp.remakeConstraints { [weak self] make in
            make.height.equalTo(labelHeight)
            make.left.equalTo(primaryButton.snp.right).offset(defaultPadding)
            make.right.equalTo(dismissButton.snp.left).offset(-defaultPadding)
            make.top.equalTo(primaryButton.snp.top)
        }
        
        subtitleLabel.snp.remakeConstraints { [weak self] make in
            make.height.equalTo(labelHeight)
            make.left.equalTo(titleLabel.snp.left)
            make.right.equalTo(titleLabel.snp.right)
            make.top.equalTo(titleLabel.snp.bottom)
        }
        
        executionDurationLabel.snp.remakeConstraints { [weak self] make in
            make.height.equalTo(labelHeight)
            make.width.equalTo(executionDurationLabel.snp.height).multipliedBy(1.75)
            make.left.equalTo(titleLabel.snp.left)
            make.top.equalTo(titleLabel.snp.bottom)
        }
        
        timeRemainingLabel.snp.remakeConstraints { [weak self] make in
            make.height.equalTo(executionDurationLabel.snp.height)
            make.width.equalTo(executionDurationLabel.snp.width)
            make.right.equalToSuperview().offset(-15)
            make.top.equalTo(executionDurationLabel.snp.top)
        }
        
        progressView.snp.remakeConstraints { [weak self] make in
            make.left.equalTo(executionDurationLabel.snp.right)
            make.right.equalTo(timeRemainingLabel.snp.left)
            make.height.equalTo(4)
            make.centerY.equalTo(executionDurationLabel.snp.centerY)
        }
        
        detailsButton.snp.remakeConstraints { [weak self] make in
            make.top.equalTo(95)
            make.height.equalTo(35)
            make.left.equalToSuperview().offset(defaultPadding * 2)
            make.right.equalToSuperview().offset(-defaultPadding * 2)
        }
        
        messagesTextView.snp.remakeConstraints { [weak self] make in
            make.top.equalTo(80)
            make.left.equalToSuperview().offset(defaultPadding * 3)
            make.right.equalToSuperview().offset(-defaultPadding)
            make.bottom.equalToSuperview().offset(-defaultPadding)
        }
        
        dismissButton.snp.remakeConstraints { [weak self] make in
            make.height.equalTo(24)
            make.width.equalTo(dismissButton.snp.height)
            make.top.equalToSuperview().offset(defaultPadding)
            make.right.equalToSuperview().offset(-defaultPadding)
        }
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
        
        if let cameraFocusCalibrationsRequired = missionExecutor.cameraFocusCalibrationsRequired {
            let calibrationsPending = cameraFocusCalibrationsRequired.filter { Dronelink.shared.get(cameraFocusCalibration: $0.with(droneSerialNumber: session.serialNumber)) == nil }
            if let calibration = calibrationsPending.first {
                DronelinkUI.shared.showDialog(
                    title: "MissionExecutorWidget.cameraFocusCalibrationsRequired.title".localized,
                    details: String(format: (calibrationsPending.count > 1 ? "MissionExecutorWidget.cameraFocusCalibrationsRequired.message.multiple" :  "MissionExecutorWidget.cameraFocusCalibrationsRequired.message.single").localized, "\(calibrationsPending.count)"),
                    actions: [
                        MDCAlertAction(title: "continue".localized, emphasis: .high, handler: { [weak self] action in
                            Dronelink.shared.request(cameraFocusCalibration: calibration)
                        }),
                        MDCAlertAction(title: "cancel".localized, handler: { [weak self] action in
                        })
                    ])
                return
            }
        }
        
        promptConfirmation()
    }
    
    @objc func onDetails(sender: Any) {
        guard
            let detailsURL = missionExecutor?.detailsURL,
            let url = URL(string: detailsURL) else {
            return
        }
        
        let embed = EmbedViewController()
        embed.networkError = "MissionExecutorWidget.details.network.error".localized
        embed.title = missionExecutor?.descriptors.name
        let nav = UINavigationController(rootViewController: embed)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true) {
            embed.load(URLRequest(url: url))
        }
    }
    
    private func promptConfirmation() {
        guard let missionExecutor = missionExecutor else { return }
        
        if missionExecutor.engagementCount > 0,
            let confirmationMessage = missionExecutor.reengagementRules.confirmationMessage {
            var actions = [
                MDCAlertAction(title: "resume".localized, emphasis: .high, handler: { [weak self] action in
                    self?.promptTakeoffLocationWarning()
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
            actualTakeoffLocation.distance(from: suggestedTakeoffLocation) > 300.convertFeetToMeters {
            if let deviceLocation = Dronelink.shared.location?.value, deviceLocation.verticalAccuracy >= 0 {
                missionExecutor.droneTakeoffAltitudeAlternate = deviceLocation.altitude
            }

            let distance = Dronelink.shared.format(formatter: "distance", value: actualTakeoffLocation.distance(from: suggestedTakeoffLocation))
            let altitude = missionExecutor.droneTakeoffAltitudeAlternate == nil ? nil : Dronelink.shared.format(formatter: "altitude", value: missionExecutor.droneTakeoffAltitudeAlternate!)
            DronelinkUI.shared.showDialog(
                title: "MissionExecutorWidget.start.takeoffLocationWarning.title".localized,
                details: altitude != nil && missionExecutor.elevationsRequired
                    ? String(format: "MissionExecutorWidget.start.takeoffLocationWarning.message.device.altitude.available".localized, distance, altitude!)
                    : String(format: "MissionExecutorWidget.start.takeoffLocationWarning.message.device.altitude.unavailable".localized, distance),
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
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard
                let missionExecutorWidget = self,
                let _ = missionExecutorWidget.missionExecutor,
                let _ = missionExecutorWidget.session
            else {
                self?.stopCountdown()
                return
            }
            
            missionExecutorWidget.countdownRemaining -= 1
            if (missionExecutorWidget.countdownRemaining == 0) {
                missionExecutorWidget.stopCountdown(aborted: false)
                missionExecutorWidget.engageOnMissionEstimated = true
                if !missionExecutorWidget.estimateMission() {
                    missionExecutorWidget.engage()
                }
            }
            else {
                missionExecutorWidget.update()
                if (missionExecutorWidget.countdownRemaining % 20 == 0) {
                    Dronelink.shared.announce(message: "\(missionExecutorWidget.countdownRemaining / 20)")
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
            Dronelink.shared.announce(message: "ExecutableWidget.start.cancelled".localized)
        }
    }
    
    private func engage() {
        engageOnMissionEstimated = false
        DispatchQueue.main.async { [weak self] in
            guard
                let missionExecutor = self?.missionExecutor,
                let session = self?.session
            else {
                return
            }

            do {
                try missionExecutor.engage(droneSession: session) { disallowed in
                    DronelinkUI.shared.showDialog(title: disallowed.title, details: disallowed.details)
                    DispatchQueue.main.async {
                        self?.update()
                    }
                }
            }
            catch DronelinkError.droneSerialNumberUnavailable {
                DronelinkUI.shared.showDialog(title: "ExecutableWidget.start.engage.droneSerialNumberUnavailable.title".localized, details: "ExecutableWidget.start.engage.droneSerialNumberUnavailable.message".localized)
                self?.update()
            }
            catch {
                self?.update()
            }
        }
    }
    
    @objc func onLayoutToggle() {
        layout = layout == .small ? .medium : .small
        view.superview?.setNeedsUpdateConstraints()
    }
    
    @objc func onDismiss() {
        Dronelink.shared.unloadMission()
    }
    
    @objc open override func update() {
        super.update()
        
        guard let missionExecutor = missionExecutor else {
            return
        }

        titleLabel.text = missionExecutor.descriptors.display

        let detailsPossible = missionExecutor.detailsURL != nil
        
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
            detailsButton.isHidden = !detailsPossible
            detailsButton.isEnabled = false

            activityIndicator.startAnimating()
            subtitleLabel.text = "MissionExecutorWidget.estimating".localized
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
            detailsButton.isHidden = !detailsPossible
            detailsButton.isEnabled = false

            activityIndicator.stopAnimating()
            let progress = Float(countdownMax - countdownRemaining) / Float(countdownMax)
            primaryButton.isEnabled = true
            primaryButton.setBackgroundColor(primaryDisengagedColor.interpolate(primaryEngagedColor, percent: CGFloat(progress)))
            primaryButton.setImage(cancelImage, for: .normal)
            titleLabel.text = String(format: "ExecutableWidget.start.countdown".localized, Int(ceil(Double(countdownRemaining) / 20)))
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
            detailsButton.isHidden = !detailsPossible
            detailsButton.isEnabled = false

            subtitleLabel.text = "ExecutableWidget.start.engaging".localized
            return
        }
        
        var estimateTime = 0.0
        var executionDuration = 0.0
        if let estimate = missionExecutor.estimate {
            estimateTime = estimate.time
            executionDuration = missionExecutor.executionDuration
        }
        let timeRemaining = estimateTime - executionDuration

        activityIndicator.isHidden = true
        primaryButton.isHidden = false
        subtitleLabel.isHidden = true
        executionDurationLabel.isHidden = false
        timeRemainingLabel.isHidden = false
        progressView.isHidden = false
        countdownProgressView.isHidden = true
        dismissButton.isHidden = missionExecutor.engaged
        messagesTextView.isHidden = false
        detailsButton.isHidden = missionExecutor.engaged || !detailsPossible
        detailsButton.isEnabled = !missionExecutor.engaged

        activityIndicator.stopAnimating()
        primaryButton.isEnabled = session != nil
        executionDurationLabel.text = Dronelink.shared.format(formatter: "timeElapsed", value: executionDuration, defaultValue: "ExecutableWidget.executionDuration.empty".localized)
        timeRemainingLabel.text = "\(timeRemaining < 0 ? "+" : "")\(Dronelink.shared.format(formatter: "timeElapsed", value: abs(timeRemaining), defaultValue: "ExecutableWidget.executionDuration.empty".localized))"
        progressView.setProgress(Float(min(estimateTime == 0 ? 0 : executionDuration / estimateTime, 1)), animated: true)

        if missionExecutor.engaged {
            progressView.progressTintColor = progressEngagedColor
            messagesTextView.text = layout == .small ? nil : missionExecutor.executingMessageGroups.map({ $0.display }).joined(separator: "\n\n")
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
            let tolerance = 4.0
            if previousEstimateContext.coordinate.distance(to: estimateContext.coordinate) < tolerance && abs(previousEstimateContext.altitude - estimateContext.altitude) < tolerance {
                return false
            }
        }
        
        previousEstimateContext = estimateContext
        missionExecutor.estimate(droneSession: self.session, altitudeRequired: true, timeRequired: true)
        return true
    }

    open override func onMissionLoaded(executor: MissionExecutor) {
        super.onMissionLoaded(executor: executor)
        
        if let expanded = executor.userInterfaceSettings?.missionDetailsExpanded {
            layout = expanded ? .medium : .small
        }
        previousEstimateContext = nil
        estimateMission()
    }
    
    open override func onMissionUnloaded(executor: MissionExecutor) {
        super.onMissionUnloaded(executor: executor)
        previousEstimateContext = nil
    }
    
    open override func onLocated(session: DroneSession) {
        super.onLocated(session: session)
        estimateMission()
    }
    
    open override func onMissionEstimated(executor: MissionExecutor, estimate: MissionExecutor.Estimate) {
        super.onMissionEstimated(executor: executor, estimate: estimate)
        
        if self.engageOnMissionEstimated {
            self.engage()
            return
        }
    }
    
    open override func onMissionEngaging(executor: MissionExecutor) {
        super.onMissionEngaging(executor: executor)
        Dronelink.shared.announce(message: "MissionExecutorWidget.engaging".localized)
    }
    
    open override func onMissionEngaged(executor: MissionExecutor, engagement: MissionExecutor.Engagement) {
        super.onMissionEngaged(executor: executor, engagement: engagement)
    }
    
    open override func onMissionDisengaged(executor: MissionExecutor, engagement: MissionExecutor.Engagement, reason: Kernel.Message) {
        super.onMissionDisengaged(executor: executor, engagement: engagement, reason: reason)
        
        if (reason.title != "MissionDisengageReason.user.disengaged".localized) {
            DronelinkUI.shared.showDialog(title: reason.title, details: reason.details)
        }
        
        if executor.status.completed {
            DispatchQueue.main.async {
                Dronelink.shared.unloadMission()
                Dronelink.shared.announce(message: reason.title)
            }
            return
        }

        Dronelink.shared.announce(message: "MissionExecutorWidget.disengaged".localized)
    }
}
