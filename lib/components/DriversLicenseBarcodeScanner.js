import React from 'react';
import { requireNativeComponent, View, ViewPropTypes } from 'react-native';
import PropTypes from 'prop-types';

const viewPropTypes = ViewPropTypes || View.propTypes;

class DriversLicenseBarcodeScanner extends React.Component {
  static propTypes = {
    active: PropTypes.bool.isRequired,
    license: PropTypes.string.isRequired,
    onError: PropTypes.func,
    onSuccess: PropTypes.func,
    torch: PropTypes.bool,
    ...viewPropTypes,
  };

  static defaultProps = {
    onError: () => {},
    onSuccess: () => {},
    torch: false,
    active: true,
  };

  _handleSuccess = (event) => {
    const { onSuccess } = this.props;

    onSuccess(event.nativeEvent.value);
  };

  _handleError = (event) => {
    const { onError } = this.props;

    onError(event.nativeEvent.value);
  }

  render() {
    const DriversLicenseBarcodeScannerComponent = getDriversLicenseBarcodeScannerComponent();

    // TODO: Is `style` needed here?

    return (
      <DriversLicenseBarcodeScannerComponent
        license={this.props.license}
        onError={this._handleError}
        onSuccess={this._handleSuccess}
        style={{ flex: 1 }}
        torch={this.props.torch}
      />
    );
  }
}

const nativeComponent = Component =>
  requireNativeComponent(Component, DriversLicenseBarcodeScanner, {});
const driversLicenseBarcodeScanner = nativeComponent(
  'DriversLicenseBarcodeScanner'
);
const getDriversLicenseBarcodeScannerComponent = () =>
  driversLicenseBarcodeScanner;

export default DriversLicenseBarcodeScanner;
