package com.mopub.mobileads;

import java.lang.reflect.Constructor;
import java.util.HashMap;
import java.util.Map;

import com.mopub.mobileads.CustomEventInterstitial;
import com.mopub.mobileads.MoPubInterstitial.MoPubInterstitialListener;

import android.content.Context;
import android.util.Log;

public class CustomEventInterstitialAdapter extends BaseInterstitialAdapter implements CustomEventInterstitial.Listener {
    private CustomEventInterstitial mCustomEventInterstitial;
    private Context mContext;
    private AdView mAdView;
    private Map<String, Object> mLocalExtras = new HashMap<String, Object>();
    private Map<String, String> mServerExtras = new HashMap<String, String>();
    
    @Override
    public void init(MoPubInterstitial moPubInterstitial, String className) {
        init(moPubInterstitial, className, null);
    }
    
    public void init(MoPubInterstitial moPubInterstitial, String className, String jsonParams) {
        super.init(moPubInterstitial, jsonParams);
        
        mContext = moPubInterstitial.getActivity();
        mAdView = moPubInterstitial.getAdView();
        
        Log.d("MoPub", "Attempting to invoke custom event: " + className);
        
        try {
            // Instantiate the provided custom event class, if possible
            Class<? extends CustomEventInterstitial> interstitialClass = Class.forName(className)
                    .asSubclass(CustomEventInterstitial.class);
            Constructor<?> interstitialConstructor = interstitialClass.getConstructor((Class[]) null);
            mCustomEventInterstitial = (CustomEventInterstitial) interstitialConstructor.newInstance();
        } catch (Exception exception) {
            Log.d("MoPub", "Couldn't invoke custom event: " + className + ".");
        }
        
        // Attempt to load the JSON extras into mServerExtras.
        try {
            mServerExtras = Utils.jsonStringToMap(jsonParams);
        } catch (Exception exception) {
            Log.d("MoPub", "Failed to create Map from JSON: " + jsonParams);
        }
        
        mLocalExtras = mInterstitial.getLocalExtras();
    }
    
    @Override
    public void loadInterstitial() {
        if (isInvalidated() || mCustomEventInterstitial == null) return;
        
        mCustomEventInterstitial.loadInterstitial(mContext, this, mLocalExtras, mServerExtras);
    }
    
    @Override
    public void showInterstitial() {
        if (isInvalidated() || mCustomEventInterstitial == null) return;
        
        mCustomEventInterstitial.showInterstitial();
    }

    @Override
    public void invalidate() {
        if (mCustomEventInterstitial != null) mCustomEventInterstitial.onInvalidate();
        mCustomEventInterstitial = null;
        mContext = null;
        mAdView = null;
        mServerExtras = null;
        mLocalExtras = null;
        super.invalidate();
    }

    /*
     * CustomEventInterstitial.Listener implementation
     */
    @Override
    public void onAdLoaded() {
        if (mAdView != null) mAdView.setIsLoading(false);
        
        if (mInterstitial != null && mInterstitial.getListener() != null) {
            MoPubInterstitialListener listener = mInterstitial.getListener();
            listener.OnInterstitialLoaded();
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
    public void onLeaveApplication() {
    }

    @Override
    public void onShowInterstitial() {
        if (mAdView != null) mAdView.trackImpression();
    }

    @Override
    public void onDismissInterstitial() {
    }
}
