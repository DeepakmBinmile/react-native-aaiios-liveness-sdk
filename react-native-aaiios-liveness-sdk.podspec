require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-aaiios-liveness-sdk"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.description  = <<-DESC
                  react-native-aaiios-liveness-sdk
                   DESC
  s.homepage     = "https://github.com/github_account/react-native-aaiios-liveness-sdk"
  # brief license entry:
  s.license      = "MIT"
  # optional - use expanded license entry instead:
  # s.license    = { :type => "MIT", :file => "LICENSE" }
  s.authors      = { "Your Name" => "yourname@email.com" }
  s.platforms    = { :ios => "9.0" }
  s.source       = { :git => "https://github.com/github_account/react-native-aaiios-liveness-sdk.git", :tag => "#{s.version}" }

  s.resources = "ios/AAILivenessSDK/Resource/*.bundle"
  s.source_files = "ios/AAILivenessSDK/AAILiveness/*.{h,m}"
  s.requires_arc = true
  s.vendored_frameworks = 'ios/AAILivenessSDK/AAILivenessSDK.xcframework'

  s.frameworks = 'AVFoundation', 'CoreMotion', 'SystemConfiguration', 'CoreTelephony'
  s.ios.library = 'c++', 'z'

  s.dependency "React"
  # ...
  # s.dependency "..."
end

