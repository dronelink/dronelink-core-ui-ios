//
//  SettingsTableViewController.swift
//  DronelinkCoreUI
//
//  Created by santiago on 8/4/21.
//

import Foundation
import SnapKit

public protocol SettingsTableDelegate {
    func showSettingOptions(setting: CameraMenuSetting)
}

public class SettingsTableViewCell: UITableViewCell {
    
    let switchView = UISwitch()
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(switchView)
        switchView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(4)
            make.bottom.equalToSuperview().inset(4)
            make.trailing.equalToSuperview().inset(4)
        }
        switchView.isHidden = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class SettingsTableViewController: UITableViewController {
    
    public var settingsDelegate: SettingsTableDelegate?
    public var settings: [CameraMenuSetting] = []

    public override func viewDidLoad() {
        tableView.register(SettingsTableViewCell.self, forCellReuseIdentifier: SettingsTableViewCell.description())
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsTableViewCell.description(), for: indexPath)
        let setting = settings[indexPath.row]
        cell.textLabel?.text = setting.displayName
        
        guard let settingsCell = cell as? SettingsTableViewCell else { return cell }
        settingsCell.switchView.isHidden = setting.settingStyle != .toggle
        return settingsCell
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let setting = settings[indexPath.row]
        if setting.settingStyle == .options {
            settingsDelegate?.showSettingOptions(setting: settings[indexPath.row])
        }
    }
}
