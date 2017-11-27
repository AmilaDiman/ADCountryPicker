Pod::Spec.new do |s|
  s.name         = 'ADCountryPicker'
  s.version      = '2.0.0'
  s.summary      = "ADCountryPicker is a swift country picker controller. Provides country name, ISO 3166 country codes, and calling codes"
  s.homepage     = "https://github.com/AmilaDiman/ADCountryPicker"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Amila Dimantha"  => "https://github.com/AmilaDiman/ADCountryPicker" }
  s.social_media_url   = "https://twitter.com/amiladiman"

  s.platform     = :ios
  s.ios.deployment_target = "8.0"
  s.source       = { :git => "https://github.com/AmilaDiman/ADCountryPicker.git", :tag => '2.0.0' }
  s.source_files  = 'Source/*.swift'
  s.resources = ['Source/assets.bundle', 'Source/CallingCodes.plist']
  s.requires_arc = true
end
