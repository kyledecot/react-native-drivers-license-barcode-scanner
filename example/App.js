import React from 'react';
import { StyleSheet, Text, View, Platform, Alert, TouchableOpacity } from 'react-native';
import DriversLicenseBarcodeScanner from 'react-native-drivers-license-barcode-scanner';

// @see https://manateeworks.com/barcode-scanner-sdk

const IOS_LICENSE = 'NEUk2MDE1uCn4q+GyGFy8VGeeLeIcUT5dt6REiaI5lM=';
const ANDROID_LICENSE = 'umDQbMBzRwwXVuRPBtLbzcYfPd0SVfpSoq3wVebSGtw=';

export default class App extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      value: null,
      flash: false,
    };
  }
  _flash() {
    return this.state.flash;
  }

  _license = () => {
    if (Platform.OS === 'ios') {
      return IOS_LICENSE;
    }

    return ANDROID_LICENSE;
  }

  _handleSuccess = (value) => {
    this.setState({
      value,
    });
  }

  _handleError = (error) => {
    Alert.alert('Error', error);
  }

  _renderValue() {
    if (!this.state.value) {
      return null;
    }

    return (
      <TouchableOpacity
        onPress={this._handlePress}
      >
        <Text style={styles.value}>{this.state.value}</Text>
      </TouchableOpacity>
    );
  }

  _handlePress = () => {
    this.setState({
      value: null,
    });
  }

  _handleToggleFlash = () => {
    this.setState({
      flash: !this.state.flash,
    });
  }

  _renderControls() {
    return (
      <TouchableOpacity
        style={styles.toggleFlashContainer}
        onPress={this._handleToggleFlash}
      >
        <Text
          style={{
            fontSize: 40,
            textAlign: 'center',
          }}
        >Toggle the Flash
        </Text>
      </TouchableOpacity>
    );
  }


  render() {
    return (
      <View style={styles.container}>
        {this._renderControls()}
        <DriversLicenseBarcodeScanner
          style={{ flex: 1 }}
          license={this._license()}
          flash={this._flash()}
          onSuccess={this._handleSuccess}
          onError={this._handleError}
        />
        {this._renderValue()}
      </View>
    );
  }
}

const styles = StyleSheet.create({
  toggleFlashContainer: {
    // ...StyleSheet.absoluteFillObject,
  },
  value: {
    fontSize: 20,
    color: '#F00',
    backgroundColor: 'transparent',
  },
  container: {
    flex: 1,
  },
});
