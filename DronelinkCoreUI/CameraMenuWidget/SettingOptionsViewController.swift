//
//  SettingOptionsViewController.swift
//  DronelinkCoreUI
//
//  Created by santiago on 8/4/21.
//

import Foundation
import UIKit

public protocol SettingsOptionsDelegate {
    func hideSettingOptions()
    func didSelectOption(_ option: CameraMenuOption, for setting: CameraMenuSetting)
}

public class SettingOptionsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let reuseIdentifier = "cell"
    public var delegate: SettingsOptionsDelegate? = nil
    public let topBar = UIView()
    public let optionsTableView = UITableView()
    public let backButton = UIButton()
    public let titleLabel = UILabel()
    public var setting: CameraMenuSetting? {
        didSet {
            titleLabel.text = setting?.displayName
            optionsTableView.reloadData()
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        optionsTableView.dataSource = self
        optionsTableView.delegate = self
        optionsTableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        optionsTableView.alwaysBounceVertical = false
        
        view.addSubview(topBar)
        view.addSubview(optionsTableView)
        
        topBar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.height.equalTo(40)
        }
        optionsTableView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.top.equalTo(topBar.snp.bottom)
        }
        
        topBar.addSubview(backButton)
        topBar.addSubview(titleLabel)
        topBar.backgroundColor = .black
        backButton.setTitle("back".localized, for: .normal)
        backButton.addTarget(self, action: #selector(backButtonAction), for: .touchUpInside)
        
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().inset(8)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualTo(backButton.snp.trailing)
        }
    }
    
    @objc func backButtonAction() {
        delegate?.hideSettingOptions()
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return setting?.options.count ?? 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        cell.textLabel?.text = setting?.options[indexPath.row].displayName
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let setting = setting else { return }
        delegate?.didSelectOption(setting.options[indexPath.row], for: setting)
    }
}
