import React from 'react';
import { requireNativeComponent, View, ViewPropTypes } from 'react-native';
import PropTypes from 'prop-types';

const viewPropTypes = ViewPropTypes || View.propTypes;

class DriversLicenseBarcodeScanner extends React.Component {
  static propTypes = {
    onSuccess: PropTypes.func,
    ...viewPropTypes,
  }

  static defaultProps = {
    onSuccess: () => {},
  }

  _handleSuccess = (value) => {
    const { onSuccess } = this.props;

    onSuccess(value);
  }

  render() {
    const DriversLicenseBarcodeScannerComponent = getDriversLicenseBarcodeScannerComponent();
    return (
      <View style={{ flex: 1, backgroundColor: '#F00' }}>
        <DriversLicenseBarcodeScannerComponent
          style={{ flex: 1 }}
          onSuccess={event => this._handleSuccess(event.nativeEvent.value)}
        />
      </View>
    );
  }
}

const nativeComponent = Component =>
  requireNativeComponent(Component, DriversLicenseBarcodeScanner, {});
const driversLicenseBarcodeScanner = nativeComponent('DriversLicenseBarcodeScanner');
const getDriversLicenseBarcodeScannerComponent = () => driversLicenseBarcodeScanner;

export default DriversLicenseBarcodeScanner;
