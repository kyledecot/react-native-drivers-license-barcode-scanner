import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import DriversLicenseBarcodeScanner from 'react-native-drivers-license-barcode-scanner';

export default class App extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      value: null,
    };
  }

  _showValue(value) {
    this.setState({
      value,
    });
  }

  _renderValue() {
    if (!this.state.value) {
      return null;
    }

    return (<Text style={styles.value}>{this.state.value}</Text>);
  }

  render() {
    return (
      <View style={{ flex: 1 }}>
        <DriversLicenseBarcodeScanner
          style={styles.container}
          onSuccess={value => this._showValue(value)}
        />
        {this._renderValue()}

      </View>
    );
  }
}

const styles = StyleSheet.create({
  value: {
    fontSize: 20,
    color: '#F00',
    backgroundColor: 'transparent',
  },
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
