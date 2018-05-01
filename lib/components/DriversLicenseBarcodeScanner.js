import React from "react";
import { requireNativeComponent, View, ViewPropTypes } from "react-native";
import PropTypes from "prop-types";

const viewPropTypes = ViewPropTypes; // || View.propTypes;

class DriversLicenseBarcodeScanner extends React.Component {
  static propTypes = {
    onSuccess: PropTypes.func,
    license: PropTypes.string.isRequired,
    flash: PropTypes.bool,
    onError: PropTypes.func,
    ...viewPropTypes
  };

  static defaultProps = {
    onError: () => {},
    onSuccess: () => {},
    flash: false
  };

  _handleSuccess = value => {
    const { onSuccess } = this.props;

    onSuccess(value);
  };

  _handleError(error) {
    const { onError } = this.props;

    onError(error);
  }

  render() {
    const DriversLicenseBarcodeScannerComponent = getDriversLicenseBarcodeScannerComponent();
    return (
      <View style={{ flex: 1, backgroundColor: "#F00" }}>
        <DriversLicenseBarcodeScannerComponent
          style={{ flex: 1 }}
          license={this.props.license}
          onSuccess={event => this._handleSuccess(event.nativeEvent.value)}
          onError={event => this._handleError(event.nativeEvent.value)}
          flash={this.props.flash}
        />
      </View>
    );
  }
}

const nativeComponent = Component =>
  requireNativeComponent(Component, DriversLicenseBarcodeScanner, {});
const driversLicenseBarcodeScanner = nativeComponent(
  "DriversLicenseBarcodeScanner"
);
const getDriversLicenseBarcodeScannerComponent = () =>
  driversLicenseBarcodeScanner;

export default DriversLicenseBarcodeScanner;
