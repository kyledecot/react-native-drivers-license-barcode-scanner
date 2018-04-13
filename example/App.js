import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import DriversLicenseBarcodeScanner from 'react-native-drivers-license-barcode-scanner';

export default class App extends React.Component {
  render() {
    return (
      <DriversLicenseBarcodeScanner style={styles.container} />
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f00',
    alignItems: 'center',
    justifyContent: 'center',
  },
});
