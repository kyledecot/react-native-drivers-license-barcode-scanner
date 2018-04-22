import React from 'react';
import { StyleSheet, Text, View, UIManager } from 'react-native';
import DriversLicenseBarcodeScanner from 'react-native-drivers-license-barcode-scanner';

export default class App extends React.Component {
  render() {
    return (
      <DriversLicenseBarcodeScanner
        style={styles.container}
        ref={(r) => this._ref = r}
       />
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 0.5,
    backgroundColor: '#fd0',
    alignItems: 'center',
    justifyContent: 'center',
  },
});
