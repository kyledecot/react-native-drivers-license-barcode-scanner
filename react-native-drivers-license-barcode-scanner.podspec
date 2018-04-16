require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name = package['name']
  s.version = package['version']
  s.source_files = 'lib/ios/DriversLicenseBarcodeScanner/**/*.{h,m}'
  s.authors = {
    'Kyle Decot' => 'kyle.decot@icloud.com'
  }
  s.summary = 'React Native Component for Scanning Drivers Licenses'
  s.license = "MIT"
  s.homepage = "https://github.com/kyledecot/react-native-drivers-license-barcode-scanner"

  s.source = {
    :git => "https://github.com/kyledecot/react-native-drivers-license-barcode-scanner.git"
  }

  s.platform     = :ios, "8.0"

  s.dependency 'React'
end
