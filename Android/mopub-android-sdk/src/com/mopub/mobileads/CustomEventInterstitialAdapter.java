package com.mopub.mobileads;

import java.lang.reflect.Constructor;
import java.util.HashMap;
import java.util.Map;

import com.mopub.mobileads.CustomEventInterstitial;

import android.content.Context;
import android.util.Log;

public class CustomEventInterstitialAdapter extends BaseInterstitialAdapter implements CustomEventInterstitial.Listener {
    private CustomEventInterstitial mCustomEventInterstitial;
    private Context mContext;
    private Map<String, Object> mLocalExtras = new HashMap<String, Object>();
    private Map<String, String> mServerExtras = new HashMap<String, String>();
    
    @Override
    public void init(MoPubInterstitial moPubInterstitial, String className) {
        init(moPubInterstitial, className, null);
    }
    
    public void init(MoPubInterstitial moPubInterstitial, String className, String jsonParams) {
        super.init(moPubInterstitial, jsonParams);
        
        mContext = moPubInterstitial.getActivity();
        
        Log.d("MoPub", "Attempting to invoke custom event: " + className);
        
        try {
            // Instantiate the provided custom event class, if possible
            Class<? extends CustomEventInterstitial> interstitialClass = Class.forName(className)
                    .asSubclass(CustomEventInterstitial.class);
            Constructor<?> interstitialConstructor = interstitialClass.getConstructor((Class[]) null);
            mCustomEventInterstitial = (CustomEventInterstitial) interstitialConstructor.newInstance();
        } catch (Exception exception) {
            Log.d("MoPub", "Couldn't locate or instantiate custom event: " + className + ".");
            if (mAdapterListener != null) mAdapterListener.onNativeInterstitialFailed(this);
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
        mServerExtras = null;
        mLocalExtras = null;
        super.invalidate();
    }

    /*
     * CustomEventInterstitial.Listener implementation
     */
    @Override
    public void onAdLoaded() {
        if (isInvalidated()) return;
        
        if (mAdapterListener != null) mAdapterListener.onNativeInterstitialLoaded(this);
    }

    @Override
    public void onAdFailed() {
        if (isInvalidated()) return;
        
        if (mAdapterListener != null) mAdapterListener.onNativeInterstitialFailed(this);
    }

    @Override
    public void onClick() {
        if (isInvalidated()) return;
        
        if (mAdapterListener != null) mAdapterListener.onNativeInterstitialClicked(this);
    }

    @Override
    public void onLeaveApplication() {
    }

    @Override
    public void onShowInterstitial() {
    }

    @Override
    public void onDismissInterstitial() {
        if (isInvalidated()) return;
        
        // Upon dismissing an interstitial, make sure any pre-fetched interstitials are expired.
        if (mAdapterListener != null) mAdapterListener.onNativeInterstitialExpired(this);
    }
}
