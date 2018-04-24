import React from 'react';
import { StyleSheet } from 'react-native';
import DriversLicenseBarcodeScanner from 'react-native-drivers-license-barcode-scanner';

export default class App extends React.Component {
  render() {
    return (
      <DriversLicenseBarcodeScanner
        style={styles.container}
        ref={r => (this._ref = r)}
      />
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
