require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name = 'react-native-drivers-license-barcode-scanner'
  s.version = package['version']
  s.source_files = 'lib/ios/DriversLicenseBarcodeScanner/**/*.{h,m}'
  s.license      = "MIT"
  s.homepage     = "https://github.com/kyledecot/react-native-drivers-license-barcode-scanner"

  s.source = {
    :git => "https://github.com/kyledecot/react-native-drivers-license-barcode-scanner.git"
  }

  s.add_dependency 'React'
end
