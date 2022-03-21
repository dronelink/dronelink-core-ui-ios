Pod::Spec.new do |s|
  s.name = "DronelinkCoreUI"
  s.version = "3.3.1"
  s.summary = "Dronelink core UI components"
  s.homepage = "https://dronelink.com/"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.author = { "Dronelink" => "dev@dronelink.com" }
  s.swift_version = "5.0"
  s.platform = :ios
  s.ios.deployment_target  = "12.0"
  s.source = { :git => "https://github.com/dronelink/dronelink-core-ui-ios.git", :tag => "#{s.version}" }
  s.source_files  = "DronelinkCoreUI/**/*.swift"
  s.resources = "DronelinkCoreUI/**/*.{strings,xcassets}"
  s.pod_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
  s.dependency "DronelinkCore", "~> 3.3.1"
  s.dependency "SnapKit", "~> 5.0.1"
  s.dependency "SwiftyUserDefaults", "~> 5.3.0"
  s.dependency "MicrosoftMapsSDK", "~> 1.2.0"
  s.dependency "Mapbox-iOS-SDK", "~> 6.4.0"
  s.dependency "MaterialComponents/Palettes", "~> 124.2.0"
  s.dependency "MaterialComponents/Buttons", "~> 124.2.0"
  s.dependency "MaterialComponents/Buttons+Theming", "~> 124.2.0"
  s.dependency "MaterialComponents/TextFields", "~> 124.2.0"
  s.dependency "MaterialComponents/ProgressView", "~> 124.2.0"
  s.dependency "MaterialComponents/Dialogs", "~> 124.2.0"
  s.dependency "MaterialComponents/Dialogs+Theming", "~> 124.2.0"
  s.dependency "MaterialComponents/Snackbar", "~> 124.2.0"
  s.dependency "MaterialComponents/ActivityIndicator", "~> 124.2.0"
  s.dependency "Kingfisher", "~> 7.1.0"
  s.dependency "Agrume", "~> 5.8.0"
  s.dependency "IQKeyboardManager", "~> 6.5.6"
  s.dependency "MarqueeLabel", "~> 4.3.0"
end
