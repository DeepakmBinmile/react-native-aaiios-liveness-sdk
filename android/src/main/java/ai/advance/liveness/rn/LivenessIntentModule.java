package ai.advance.liveness.sdk.rn;

import android.app.Activity;
import android.content.Intent;
import android.util.Log;


import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

import ai.advance.liveness.lib.GuardianLivenessDetectionSDK;
import ai.advance.liveness.lib.LivenessResult;
import ai.advance.liveness.sdk.activity.LivenessActivity;

/**
 * createTime:2019-10-30
 *
 * @author fan.zhang@advance.ai
 */
public class LivenessIntentModule extends ReactContextBaseJavaModule {
    private static final int REQUESTCODE_LIVENESS = 1110;
    private Callback mSuccessCallback, mErrorCallback;
    private ActivityEventListener mActivityEventListener = new ActivityEventListener() {
        @Override
        public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
            if (requestCode == LivenessIntentModule.REQUESTCODE_LIVENESS) {
                if (LivenessResult.isSuccess()) {
                    if (mSuccessCallback != null) {
                        mSuccessCallback.invoke(
                                LivenessResult.getLivenessId(),
                                LivenessResult.getLivenessBase64Str(),
                                LivenessResult.getTransactionId(),
                                LivenessResult.isPay()
                        );
                    }
                } else {
                    if (mErrorCallback != null) {
                        mErrorCallback.invoke(false, LivenessResult.getErrorMsg(), LivenessResult.getErrorCode());
                    }
                }
            }
        }

        @Override
        public void onNewIntent(Intent intent) {

        }
    };

    public LivenessIntentModule( ReactApplicationContext reactContext) {
        super(reactContext);
        reactContext.addActivityEventListener(mActivityEventListener);
    }

    @Override
    public String getName() {
        return "LivenessModule";
    }

    @ReactMethod
    public void startLiveness(Callback successCallback, Callback errorCallback) {
        Activity currentActivity = getCurrentActivity();
        if (currentActivity != null) {
            this.mSuccessCallback = successCallback;
            this.mErrorCallback = errorCallback;
            Intent intent = new Intent(currentActivity, LivenessActivity.class);
            currentActivity.startActivityForResult(intent, REQUESTCODE_LIVENESS);
        }
    }



    @ReactMethod
    public void bindUser(String userId) {
        GuardianLivenessDetectionSDK.bindUser(userId);
    }

    @ReactMethod
    public void isDetectOcclusion(boolean detectOcclusion) {
        GuardianLivenessDetectionSDK.isDetectOcclusion(detectOcclusion);
    }
    
}
