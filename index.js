import React, { Component } from 'react';
import { StyleSheet, requireNativeComponent, NativeModules, NativeEventEmitter, UIManager, findNodeHandle} from 'react-native';

let IOSLivenessView = requireNativeComponent('RNAAILivenessView');

export default class AAIIOSLivenessView extends Component<{}> {
    
    static defaultProps = {
        // This field is used to control whether to show the default loading view when sending a network request
        showHUD: true,
        // Sequence of actions detected.
        // eg: ["AAIDetectionTypeMouth", "AAIDetectionTypeBlink", "AAIDetectionTypePosYaw"]
        detectionActions: [],
        language: null,
        prepareTimeoutInterval: 10
    };

    constructor(props) {
      super(props);
      
      // Callback
      this.sdkEventCallback = {
        onCameraPermission: (errorInfo) => {
          if (errorInfo && !errorInfo.authed) {
            // Permission denied
            // {"key": "xxx", "message": "xxx"}
            if (this.props.onCameraPermissionDenied) {
                this.props.onCameraPermissionDenied(errorInfo.key, errorInfo.message)
            }            
          }
        },
        onDetectionReady: (info) => {
           // console.log('onDetectionReady: ', info)
        },
        onFrameDetected: (info) => {
          // {"key": "xxx", "state": "xxx"}
          // console.log('onFrameDetected: ', info)
        },
        onDetectionTypeChanged: (info) => {
          // {"key": "xxx", "state": "xxx"}
          // console.log('onDetectionTypeChanged: ', info)
        },
        onDetectionComplete: (info) => {
          // {"livenessId": "xxx", "img": "xxx"}
          if (this.props.onDetectionComplete) {
              this.props.onDetectionComplete(info.livenessId, info.img)
          }
        },
        onDetectionFailed: (errorInfo) => {
            // Show alert view
            // {"key": "xxx", "message": "xxx"}
            if (this.props.onDetectionFailed) {
                this.props.onDetectionFailed(errorInfo.key, errorInfo.message)
            }
          },
        livenessViewBeginRequest: (info) => {
          // Show loading view
          if (this.props.livenessViewBeginRequest) {
            this.props.livenessViewBeginRequest()
          }
        },
        onLivenessViewRequestFailed: (errorInfo) => {
          // Auth request failed
          // {"code": integer, "message": "xxx", "transactionId": "xxx"}
          if (this.props.onLivenessViewRequestFailed) {
            this.props.onLivenessViewRequestFailed(errorInfo.code, errorInfo.message, errorInfo.transactionId)
          }
        },
        livenessViewEndRequest: (errorInfo) => {
          // Close loading view
          // {"code": integer, "message": "xxx"}
          if (this.props.livenessViewEndRequest) {
            this.props.livenessViewEndRequest()
          }
        },
      }
      this._onSDKEventCallback = this.onSDKEventCallback.bind(this);
  
      const sdkEmitter = new NativeEventEmitter(NativeModules.RNAAILivenessSDKEvent);
      this.sdkEventListener = sdkEmitter.addListener('RNAAILivenessSDKEvent', this._onSDKEventCallback);
    }
  
    onSDKEventCallback(info) {
      this.sdkEventCallback[info.name](info.body)
    }
  
    componentDidMount() {
      // Set screen brightness
      UIManager.dispatchViewManagerCommand(
        this._iosLivenessView,
        UIManager.RNAAILivenessView.Commands.graduallySetBrightness,
        [1]
      )
    }
  
    componentWillUnmount() {
      // Resume brightness
      UIManager.dispatchViewManagerCommand(
        this._iosLivenessView,
        UIManager.RNAAILivenessView.Commands.graduallyResumeBrightness,[]
      )
      // Reset view state
      UIManager.dispatchViewManagerCommand(
        this._iosLivenessView,
        UIManager.RNAAILivenessView.Commands.rnViewDidDisappear,[]
      )
      if (this.sdkEventListener) {
        this.sdkEventListener.remove()
      }
    }
  
    render() {
      return <IOSLivenessView ref={(ref) => {this._iosLivenessView = findNodeHandle(ref)}} style={[styles.container, this.props.style]} {...this.props} >
                {this.props.children}
            </IOSLivenessView>
    }
  }
  
  const styles = StyleSheet.create({
    container: {
      flex: 1,
      justifyContent: 'center',
      alignItems: 'center',
      backgroundColor: '#FFFFFF',
    }
  });
  