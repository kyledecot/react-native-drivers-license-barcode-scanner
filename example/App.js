import React from 'react';
import {
  StyleSheet,
  Text,
  View,
  Platform,
  Alert,
  TouchableOpacity,
  Image,
  SafeAreaView,
} from 'react-native';
import DriversLicenseBarcodeScanner from 'react-native-drivers-license-barcode-scanner';

// @see https://manateeworks.com/barcode-scanner-sdk

const TORCH_IMAGE_ACTIVE = require('./ic_flash_on.png');
const TORCH_IMAGE_INACTIVE = require('./ic_flash_off.png');

const IOS_LICENSE = 'NEUk2MDE1uCn4q+GyGFy8VGeeLeIcUT5dt6REiaI5lM=';
const ANDROID_LICENSE = 'umDQbMBzRwwXVuRPBtLbzcYfPd0SVfpSoq3wVebSGtw=';

export default class App extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      value: null,
      torch: false,
    };
  }
  _torch() {
    return this.state.torch;
  }

  _license = () => {
    if (Platform.OS === 'ios') {
      return IOS_LICENSE;
    }

    return ANDROID_LICENSE;
  };

  _handleSuccess = value => {
    this.setState({
      value,
    });
  };

  _handleError = error => {
    Alert.alert('Error', error);
  };

  _renderValue() {
    if (!this.state.value) {
      return null;
    }

    return (
      <TouchableOpacity onPress={this._handlePress}>
        <Text style={styles.value}>{this.state.value}</Text>
      </TouchableOpacity>
    );
  }

  _handlePress = () => {
    this.setState({
      value: null,
    });
  };

  _handleToggleTorch = () => {
    this.setState({
      torch: !this.state.torch,
    });
  };

  _renderControls() {
    const source = this.state.torch ? TORCH_IMAGE_ACTIVE : TORCH_IMAGE_INACTIVE;

    return (
      <TouchableOpacity
        style={styles.toggleFlashContainer}
        onPress={this._handleToggleTorch}
      >
        <Image
          source={source}
          tintColor={'rgba(255, 0, 0, 1)'}
        />
      </TouchableOpacity>
    );
  }

  _renderOverlay() {
    return (
      <SafeAreaView style={styles.safeAreaView}>
        <View style={styles.container}>

          {this._renderControls()}
          {this._renderValue()}
        </View>
      </SafeAreaView>
    );
  }

  render() {
    return (
      <View style={styles.container}>
        <DriversLicenseBarcodeScanner
          license={this._license()}
          flash={this._torch()}
          onSuccess={this._handleSuccess}
          onError={this._handleError}
        />
        {this._renderOverlay()}
      </View>

    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  safeAreaView: {
    flex: 1,
    ...StyleSheet.absoluteFillObject,
  },
  toggleFlashContainer: {
    position: 'absolute',
    bottom: 20,
    right: 20,
    backgroundColor: 'rgba(0, 0, 0, 0.3)',
    padding: 10,
    borderRadius: 25,
    width: 50,
    height: 50,
    alignItems: 'center',
    justifyContent: 'center',
  },
  value: {
    fontSize: 20,
    color: '#F00',
    backgroundColor: 'transparent',
  },
});
