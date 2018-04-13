import React from 'react';
import PropTypes from 'prop-types';
import { NativeModules, Text, requireNativeComponent } from 'react-native';

class DriversLicenseBarcodeScanner extends React.Component {
  render() {
    const Component = requireNativeComponent('DriversLicenseBarcodeScanner', null);

    return (
      <Component />
    );
  }
}

export default DriversLicenseBarcodeScanner;
