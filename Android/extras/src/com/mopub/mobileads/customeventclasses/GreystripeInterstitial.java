package com.mopub.simpleadsdemo;

import java.util.Map;

import android.content.Context;
import android.util.Log;

import com.greystripe.sdk.GSAd;
import com.greystripe.sdk.GSAdErrorCode;
import com.greystripe.sdk.GSAdListener;
import com.greystripe.sdk.GSFullscreenAd;
import com.mopub.mobileads.CustomEventInterstitial;

/*
 * Tested with Greystripe SDK 2.1.
 */
public class GreystripeInterstitial extends CustomEventInterstitial implements GSAdListener {
    private CustomEventInterstitial.Listener mInterstitialListener;
    private GSFullscreenAd mGreystripeAd;
    
    /*
     * Abstract methods from CustomEventInterstitial
     */
    @Override
    public void loadInterstitial(Context context, CustomEventInterstitial.Listener interstitialListener,
            Map<String, Object> localExtras, Map<String, String> serverExtras) {
        mInterstitialListener = interstitialListener;

        /*
         * You may also pass this String down in the serverExtras Map by specifying Custom Event Data
         * in MoPub's web interface.
         */
        String greystripeAppId = "YOUR_GREYSTRIPE_APP_ID";
        
        mGreystripeAd = new GSFullscreenAd(context, greystripeAppId);
        mGreystripeAd.addListener(this);
        
        mGreystripeAd.fetch();
    }

    @Override
    public void showInterstitial() {
        if (!mGreystripeAd.isAdReady()) {
            mInterstitialListener.onAdFailed();
            return;
        }
        
        Log.d("MoPub", "Showing Greystripe interstitial ad.");
        mGreystripeAd.display();
        mInterstitialListener.onShowInterstitial();
    }
    
    @Override
    public void onInvalidate() {
        mGreystripeAd.removeListener(this);
    }

    /*
     * GSAdListener implementation
     */
    @Override
    public void onAdClickthrough(GSAd greystripeAd) {
        Log.d("MoPub", "Greystripe interstitial ad clicked.");
        mInterstitialListener.onClick();

        /*
         * XXX: When a Greystripe interstitial is dismissed as a result of a user click, the
         * onAdDismissal callback does not get fired. This call ensures that the custom event
         * listener is informed of all dismissals.
         */
        mInterstitialListener.onDismissInterstitial();
    }

    @Override
    public void onAdDismissal(GSAd greystripeAd) {
        Log.d("MoPub", "Greystripe interstitial ad dismissed.");
        mInterstitialListener.onDismissInterstitial();
    }

    @Override
    public void onFailedToFetchAd(GSAd greystripeAd, GSAdErrorCode errorCode) {
        Log.d("MoPub", "Greystripe interstitial ad failed to load.");
        mInterstitialListener.onAdFailed();
    }

    @Override
    public void onFetchedAd(GSAd greystripeAd) {
        if (mGreystripeAd != null && mGreystripeAd.isAdReady()) {
            Log.d("MoPub", "Greysripe interstitial ad loaded successfully.");
            mInterstitialListener.onAdLoaded();
        } else {
            mInterstitialListener.onAdFailed();
        }
    }

    @Override
    public void onAdCollapse(GSAd greystripeAd) {
    }

    @Override
    public void onAdExpansion(GSAd greystripeAd) {
    }
}
