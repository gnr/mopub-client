package com.mopub.simpleadsdemo;

import java.util.Map;

import android.app.Activity;
import android.content.Context;
import android.util.Log;

import com.chartboost.sdk.Chartboost;
import com.chartboost.sdk.ChartboostDelegate;
import com.mopub.mobileads.CustomEventInterstitial;

public class ChartboostInterstitial extends CustomEventInterstitial {
    private Chartboost mChartboostInterstitial;
    private ChartboostDelegate mChartboostDelegate;
    private CustomEventInterstitial.Listener mInterstitialListener;

    /*
     * Abstract methods from CustomEventInterstitial
     */
    @Override
    public void loadInterstitial(Context context, CustomEventInterstitial.Listener interstitialListener,
            Map<String, Object> localExtras, Map<String, String> serverExtras) {
        mInterstitialListener = interstitialListener;
        mChartboostInterstitial = Chartboost.sharedChartboost();
        mChartboostDelegate = getChartboostDelegate();
        
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
         * You may also pass these Strings down in the serverExtras Map by specifying Custom Event Data
         * in MoPub's web interface.
         */
        String appId = "YOUR_CHARTBOOST_APP_ID";
        String appSignature = "YOUR_CHARTBOOST_APP_SIGNATURE";
        
        mChartboostInterstitial.onCreate(activity, appId, appSignature, mChartboostDelegate);
        mChartboostInterstitial.startSession();
        
        mChartboostInterstitial.cacheInterstitial();
    }

    @Override
    public void showInterstitial() {
        Log.d("MoPub", "Showing Chartboost interstitial ad.");
        if (mChartboostInterstitial != null) mChartboostInterstitial.showInterstitial();
        mInterstitialListener.onShowInterstitial();
    }
    
    @Override
    public void onInvalidate() {
        mInterstitialListener = null;
        mChartboostInterstitial = null;
        mChartboostDelegate = null;
    }
    
    private ChartboostDelegate getChartboostDelegate() {
        return new ChartboostDelegate() {
            /*
             * Interstitial delegate methods
             */
            @Override
            public boolean shouldDisplayInterstitial(String location) {
                return true;
            }
            
            @Override
            public boolean shouldRequestInterstitial(String location) {
                return true;
            }
            
            @Override
            public boolean shouldRequestInterstitialsInFirstSession() {
                return true;
            }
            
            @Override
            public void didCacheInterstitial(String location) {
                Log.d("MoPub", "Chartboost interstitial loaded successfully.");
                showInterstitial();
            }
            
            @Override
            public void didFailToLoadInterstitial(String location) {
                Log.d("MoPub", "Chartboost interstitial ad failed to load.");
                mInterstitialListener.onAdFailed();
            }
            
            @Override
            public void didDismissInterstitial(String location) {
                // Note that this method is called on interstitial click and close.
            }
            
            @Override
            public void didCloseInterstitial(String location) {
                Log.d("MoPub", "Chartboost interstitial ad dismissed.");
                mInterstitialListener.onDismissInterstitial();
            }
            
            @Override
            public void didClickInterstitial(String location) {
                Log.d("MoPub", "Chartboost interstitial ad clicked.");
                mInterstitialListener.onClick();
            }
            
            @Override
            public void didShowInterstitial(String location) {
            }
            
            /*
             * More Apps delegate methods
             */
            @Override
            public boolean shouldDisplayLoadingViewForMoreApps() {
                return false;
            }
            
            @Override
            public boolean shouldRequestMoreApps() {
                return false;
            }
            
            @Override
            public boolean shouldDisplayMoreApps() {
                return false;
            }
            
            @Override
            public void didFailToLoadMoreApps() {
            }

            @Override
            public void didCacheMoreApps() {
            }
            
            @Override
            public void didDismissMoreApps() {
            }
            
            @Override
            public void didCloseMoreApps() {
            }

            @Override
            public void didClickMoreApps() {
            }

            @Override
            public void didShowMoreApps() {
            }
        };
    }
}
