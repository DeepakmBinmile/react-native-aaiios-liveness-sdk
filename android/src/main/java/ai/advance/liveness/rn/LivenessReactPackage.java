package ai.advance.liveness.sdk.rn;


import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ViewManager;

import java.util.Collections;
import java.util.List;

/**
 * createTime:2019-10-31
 *
 * @author fan.zhang@advance.ai
 */
public class LivenessReactPackage implements ReactPackage {
    @Override
    public List<NativeModule> createNativeModules( ReactApplicationContext reactContext) {
        return Collections.<NativeModule>singletonList(new LivenessIntentModule(reactContext));
    }

    @Override
    public List<ViewManager> createViewManagers( ReactApplicationContext reactContext) {
        return Collections.emptyList();
    }
}
