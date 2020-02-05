Pod::Spec.new do |s|
  s.name = "DronelinkCoreUI"
  s.version = "1.1.0"
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

  s.dependency "DronelinkCore", "~> 1.2.0"
  s.dependency "SnapKit", "~> 5.0.0"
  s.dependency "Mapbox-iOS-SDK", "~> 5.5.0"
  s.dependency "MaterialComponents/Palettes", "~> 103.1.0"
  s.dependency "MaterialComponents/Buttons", "~> 103.1.0"
  s.dependency "MaterialComponents/Buttons+Theming", "~> 103.1.0"
  s.dependency "MaterialComponents/TextFields", "~> 103.1.0"
  s.dependency "MaterialComponents/ProgressView", "~> 103.1.0"
  s.dependency "MaterialComponents/Dialogs", "~> 103.1.0"
  s.dependency "MaterialComponents/Dialogs+Theming", "~> 103.1.0"
  s.dependency "MaterialComponents/Snackbar", "~> 103.1.0"
end
