platform :ios, '13.0'
inhibit_all_warnings!
use_frameworks!

target 'DronelinkCoreUI' do
  pod 'DronelinkCore', :path => '../../private/dronelink-core-ios'
  pod 'SnapKit', '~> 5.6.0'
  pod 'SwiftyUserDefaults', '~> 5.3.0'
  pod 'MapboxMaps', '~> 11.6.1'
  pod 'MaterialComponents/Palettes', '~> 124.2.0'
  pod 'MaterialComponents/Buttons', '~> 124.2.0'
  pod 'MaterialComponents/Buttons+Theming', '~> 124.2.0'
  pod 'MaterialComponents/TextFields', '~> 124.2.0'
  pod 'MaterialComponents/ProgressView', '~> 124.2.0'
  pod 'MaterialComponents/Dialogs', '~> 124.2.0'
  pod 'MaterialComponents/Dialogs+Theming', '~> 124.2.0'
  pod 'MaterialComponents/Snackbar', '~> 124.2.0'
  pod 'MaterialComponents/ActivityIndicator', '~> 124.2.0'
  pod 'Kingfisher', '~> 7.6.2'
  pod 'MarqueeLabel', '~> 4.3.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # https://github.com/material-components/material-components-ios/issues/10209
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end