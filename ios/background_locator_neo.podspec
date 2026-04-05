#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'background_locator_neo'
  s.version          = '1.0.0'
  s.summary          = 'A modern Flutter plugin for background location updates (Neo fork).'
  s.description      = <<-DESC
A modernized fork of background_locator_fixed, updated for Flutter 3+ and Android 14.
                       DESC
  s.homepage         = 'https://github.com/upendra-bajpai/background_locator_neo'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Upendra Bajpai' => 'upendra.bajpai@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'

  s.ios.deployment_target = '11.0'
end

