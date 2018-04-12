import React from 'react';
import PropTypes from 'prop-types';
import { NativeModules, Text, requireNativeComponent } from 'react-native';
import Scanner from '';

class DriversLicenseBarcodeScanner extends React.Component {
  render() {
    const Component = requireNativeComponent('DriversLicenseBarcodeScanner', DriversLicenseBarcodeScanner, {
      nativeOnly: {},
    });

    return (
      <Component />
    );
  }
}

export default DriversLicenseBarcodeScanner;
