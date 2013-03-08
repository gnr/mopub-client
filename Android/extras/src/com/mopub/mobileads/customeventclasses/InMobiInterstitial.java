package com.mopub.simpleadsdemo;

import java.util.Map;

import android.app.Activity;
import android.content.Context;
import android.util.Log;

import com.inmobi.androidsdk.IMAdInterstitial;
import com.inmobi.androidsdk.IMAdInterstitialListener;
import com.inmobi.androidsdk.IMAdRequest.ErrorCode;
import com.mopub.mobileads.CustomEventInterstitial;

/*
 * Tested with InMobi SDK 3.6.2.
 */
public class InMobiInterstitial extends CustomEventInterstitial implements IMAdInterstitialListener {
    private CustomEventInterstitial.Listener mInterstitialListener;
    private IMAdInterstitial mInMobiInterstitial;

    /*
     * Abstract methods from CustomEventInterstitial
     */
    @Override
    public void loadInterstitial(Context context, CustomEventInterstitial.Listener interstitialListener,
            Map<String, Object> localExtras, Map<String, String> serverExtras) {
        mInterstitialListener = interstitialListener;
        
        Activity activity = null;
        if (context instanceof Activity) {
            activity = (Activity) context;
        } else {
            // You may also pass in an Activity Context in the localExtras map and retrieve it here.
        }
        
        if (activity == null) {
            mInterstitialListener.onAdFailed();
            return;
        }
        
        /*
         * You may also pass this String down in the serverExtras Map by specifying Custom Event Data
         * in MoPub's web interface.
         */
        String inMobiAppId = "YOUR_INMOBI_APP_ID";
        mInMobiInterstitial = new IMAdInterstitial(activity, inMobiAppId);
        
        mInMobiInterstitial.setIMAdInterstitialListener(this);
        mInMobiInterstitial.loadNewAd();
    }
    
    @Override
    public void showInterstitial() {
        Log.d("MoPub", "Showing InMobi interstitial ad.");
        mInMobiInterstitial.show();
        mInterstitialListener.onShowInterstitial();
    }

    @Override
    public void onInvalidate() {
        mInMobiInterstitial.setIMAdInterstitialListener(null);
    }

    /*
     * IMAdListener implementation
     */
    @Override
    public void onAdRequestFailed(IMAdInterstitial adInterstitial, ErrorCode errorCode) {
        Log.d("MoPub", "InMobi interstitial ad failed to load.");
        mInterstitialListener.onAdFailed();
    }

    @Override
    public void onAdRequestLoaded(IMAdInterstitial adInterstitial) {
        Log.d("MoPub", "InMobi interstitial ad loaded successfully.");
        mInterstitialListener.onAdLoaded();
    }

    @Override
    public void onDismissAdScreen(IMAdInterstitial adInterstitial) {
        Log.d("MoPub", "InMobi interstitial ad dismissed.");
        mInterstitialListener.onDismissInterstitial();
    }

    @Override
    public void onLeaveApplication(IMAdInterstitial adInterstitial) {
        Log.d("MoPub", "InMobi interstitial ad leaving application.");
        mInterstitialListener.onClick();
        mInterstitialListener.onLeaveApplication();
    }

    @Override
    public void onShowAdScreen(IMAdInterstitial adInterstitial) {
    }
}
