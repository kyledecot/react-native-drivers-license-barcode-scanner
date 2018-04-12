require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name = 'react-native-drivers-license-barcode-scanner'
  s.version = package['version']

  s.add_dependency 'React'
end
