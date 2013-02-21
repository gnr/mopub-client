package com.mopub.mobileads;

import java.lang.reflect.Constructor;
import java.util.HashMap;
import java.util.Map;

import com.mopub.mobileads.CustomEventBanner;

import android.content.Context;
import android.util.Log;
import android.view.View;

public class CustomEventBannerAdapter extends BaseAdapter implements CustomEventBanner.Listener {
    private AdView mAdView;
    private Context mContext;
    private CustomEventBanner mCustomEventBanner;
    private Map<String, Object> mLocalExtras = new HashMap<String, Object>();
    private Map<String, String> mServerExtras = new HashMap<String, String>();
    
    @Override
    public void init(MoPubView moPubView, String className) {
        init(moPubView, className, null);
    }
    
    public void init(MoPubView moPubView, String className, String jsonParams) {
        super.init(moPubView, jsonParams);
        
        mContext = moPubView.getContext();
        mAdView = moPubView.mAdView;
        
        Log.d("MoPub", "Attempting to invoke custom event: " + className);
        
        try {
            // Instantiate the provided custom event class, if possible
            Class<? extends CustomEventBanner> bannerClass = Class.forName(className)
                    .asSubclass(CustomEventBanner.class);
            Constructor<?> bannerConstructor = bannerClass.getConstructor((Class[]) null);
            mCustomEventBanner = (CustomEventBanner) bannerConstructor.newInstance();
        } catch (Exception exception) {
            Log.d("MoPub", "Couldn't invoke custom event: " + className + ".");
            return;
        }
        
        // Attempt to load the JSON extras into mServerExtras.
        try {
            mServerExtras = Utils.jsonStringToMap(jsonParams);
        } catch (Exception exception) {
            Log.d("MoPub", "Failed to create Map from JSON: " + jsonParams + exception.toString());
        }
        
        mLocalExtras = mMoPubView.getLocalExtras();
    }
    
    @Override
    public void loadAd() {
        if (isInvalidated() || mCustomEventBanner == null) return;
        
        mCustomEventBanner.loadAd(mContext, this, mLocalExtras, mServerExtras);
    }

    @Override
    public void invalidate() {
        if (mCustomEventBanner != null) mCustomEventBanner.onInvalidate();
        mAdView = null;
        mContext = null;
        mCustomEventBanner = null;
        mLocalExtras = null;
        mServerExtras = null;
        super.invalidate();
    }
    
    /*
     * CustomEventBanner.Listener implementation
     */
    @Override
    public void onAdLoaded() {
        if (mAdView != null) {
            mAdView.setIsLoading(false);
            mAdView.trackImpression();
            mAdView.scheduleRefreshTimerIfEnabled();
            mMoPubView.adLoaded();
        }
    }

    @Override
    public void onAdFailed() {
        if (mAdView != null) mAdView.loadFailUrl();
    }

    @Override
    public void onClick() {
        if (mAdView != null) mAdView.registerClick();
    }
    
    @Override
    public void setAdContentView(View view) {
        if (mAdView != null) mAdView.setAdContentView(view);
    }

    @Override
    public void onLeaveApplication() {
    }
}
