import React from 'react';
import { StyleSheet, Text, View, Platform } from 'react-native';
import DriversLicenseBarcodeScanner from 'react-native-drivers-license-barcode-scanner';

// @see https://manateeworks.com/barcode-scanner-sdk

const IOS_LICENSE = 'NEUk2MDE1uCn4q+GyGFy8VGeeLeIcUT5dt6REiaI5lM=';
const ANDROID_LICENSE = 'umDQbMBzRwwXVuRPBtLbzcYfPd0SVfpSoq3wVebSGtw=';

export default class App extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      value: null,
    };
  }

  _license = () => {
    if (Platform.OS === 'ios') {
      return IOS_LICENSE;
    }

    return ANDROID_LICENSE;
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
      <View style={styles.container}>
        <DriversLicenseBarcodeScanner
          style={{ flex: 1 }}
          license={this._license()}
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
