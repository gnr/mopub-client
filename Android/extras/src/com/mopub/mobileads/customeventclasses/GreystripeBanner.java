package com.mopub.simpleadsdemo;

import java.util.Map;

import android.content.Context;
import android.util.Log;

import com.greystripe.sdk.GSAd;
import com.greystripe.sdk.GSAdErrorCode;
import com.greystripe.sdk.GSAdListener;
import com.greystripe.sdk.GSMobileBannerAdView;
import com.mopub.mobileads.CustomEventBanner;

/*
 * Tested with Greystripe SDK 2.1.
 */
public class GreystripeBanner extends CustomEventBanner implements GSAdListener {
    private CustomEventBanner.Listener mBannerListener;
    private GSMobileBannerAdView mGreystripeAd;

    /*
     * Abstract methods from CustomEventBanner
     */
    @Override
    public void loadAd(Context context, CustomEventBanner.Listener bannerListener,
            Map<String, Object> localExtras, Map<String, String> serverExtras) {
        mBannerListener = bannerListener;
        
        /*
         * You may also pass this String down in the serverExtras Map by specifying Custom Event Data
         * in MoPub's web interface.
         */
        String greystripeAppId = "YOUR_GREYSTRIPE_APP_ID";
        mGreystripeAd = new GSMobileBannerAdView(context, greystripeAppId);
        mGreystripeAd.addListener(this);
        
        mGreystripeAd.refresh();
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
        Log.d("MoPub", "Greystripe banner ad clicked.");
        mBannerListener.onClick();
    }

    @Override
    public void onAdDismissal(GSAd greystripeAd) {
        Log.d("MoPub", "Greystripe banner ad modal dismissed.");
    }

    @Override
    public void onFailedToFetchAd(GSAd greystripeAd, GSAdErrorCode errorCode) {
        Log.d("MoPub", "Greystripe banner ad failed to load.");
        mBannerListener.onAdFailed();
    }

    @Override
    public void onFetchedAd(GSAd greystripeAd) {
        if (mGreystripeAd != null & mGreystripeAd.isAdReady()) {
            Log.d("MoPub", "Greystripe banner ad loaded successfully. Showing ad...");
            mBannerListener.onAdLoaded();
            mBannerListener.setAdContentView(mGreystripeAd);
        } else {
            mBannerListener.onAdFailed();
        }
    }

    @Override
    public void onAdCollapse(GSAd greystripeAd) {
    }

    @Override
    public void onAdExpansion(GSAd greystripeAd) {
    }
}
