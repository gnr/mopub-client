package com.mopub.simpleadsdemo;

import java.util.Map;

import android.app.Activity;
import android.content.Context;
import android.util.Log;

import com.inmobi.androidsdk.IMAdListener;
import com.inmobi.androidsdk.IMAdRequest.ErrorCode;
import com.inmobi.androidsdk.IMAdView;
import com.mopub.mobileads.CustomEventBanner;

/*
 * Tested with InMobi SDK 3.6.2.
 */
public class InMobiBanner extends CustomEventBanner implements IMAdListener {
    private CustomEventBanner.Listener mBannerListener;
    private IMAdView mInMobiBanner;

    /*
     * Abstract methods from CustomEventBanner
     */
    @Override
    public void loadAd(Context context, CustomEventBanner.Listener bannerListener,
            Map<String, Object> localExtras, Map<String, String> serverExtras) {
        mBannerListener = bannerListener;
        
        Activity activity = null;
        if (context instanceof Activity) {
            activity = (Activity) context;
        } else {
            // You may also pass in an Activity Context in the localExtras map and retrieve it here.
        }
        
        if (activity == null) {
            mBannerListener.onAdFailed();
            return;
        }
        
        /*
         * You may also pass this String down in the serverExtras Map by specifying Custom Event Data
         * in MoPub's web interface.
         */
        String inMobiAppId = "YOUR_INMOBI_APP_ID";
        mInMobiBanner = new IMAdView(activity, IMAdView.INMOBI_AD_UNIT_320X50, inMobiAppId);
        
        mInMobiBanner.setIMAdListener(this);
        mInMobiBanner.loadNewAd();
    }

    @Override
    public void onInvalidate() {
        mInMobiBanner.setIMAdListener(null);
    }

    /*
     * IMAdListener implementation
     */
    @Override
    public void onAdRequestCompleted(IMAdView adView) {
        if (mInMobiBanner != null) {
            Log.d("MoPub", "InMobi banner ad loaded successfully. Showing ad...");
            mBannerListener.onAdLoaded();
            mBannerListener.setAdContentView(mInMobiBanner);
        } else {
            mBannerListener.onAdFailed();
        }
    }

    @Override
    public void onAdRequestFailed(IMAdView adView, ErrorCode errorCode) {
        Log.d("MoPub", "InMobi banner ad failed to load.");
        mBannerListener.onAdFailed();
    }

    @Override
    public void onDismissAdScreen(IMAdView adView) {
        Log.d("MoPub", "InMobi banner ad modal dismissed.");
    }

    @Override
    public void onLeaveApplication(IMAdView adView) {
        Log.d("MoPub", "InMobi banner ad click has left the application context.");
        mBannerListener.onLeaveApplication();
    }

    @Override
    public void onShowAdScreen(IMAdView adView) {
        Log.d("MoPub", "InMobi banner ad clicked.");
        mBannerListener.onClick();
    }
}
