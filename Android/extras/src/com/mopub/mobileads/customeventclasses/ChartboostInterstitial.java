package com.mopub.simpleadsdemo;

import java.util.Map;

import android.app.Activity;
import android.content.Context;
import android.util.Log;

import com.chartboost.sdk.Chartboost;
import com.chartboost.sdk.ChartboostDelegate;
import com.mopub.mobileads.CustomEventInterstitial;

/*
 * Tested with Chartboost SDK 3.1.5.
 */
public class ChartboostInterstitial extends CustomEventInterstitial {
    private CustomEventInterstitial.Listener mInterstitialListener;

    /*
     * Note: Chartboost recommends implementing their specific Activity lifecycle callbacks in your
     * Activity's onStart(), onStop(), onBackPressed() methods for proper results. Please see their
     * documentation for more information.
     */

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
         * You may also pass these Strings down in the serverExtras Map by specifying Custom Event Data
         * in MoPub's web interface.
         */
        String appId = "YOUR_CHARTBOOST_APP_ID";
        String appSignature = "YOUR_CHARTBOOST_APP_SIGNATURE";
        
        Chartboost chartboost = Chartboost.sharedChartboost();
        ChartboostDelegate chartboostDelegate = getChartboostDelegate();
        
        chartboost.onCreate(activity, appId, appSignature, chartboostDelegate);
        chartboost.onStart(activity);
        
        chartboost.cacheInterstitial();
    }

    @Override
    public void showInterstitial() {
        Log.d("MoPub", "Showing Chartboost interstitial ad.");
        Chartboost.sharedChartboost().showInterstitial();
        mInterstitialListener.onShowInterstitial();
    }
    
    @Override
    public void onInvalidate() {
        Chartboost.sharedChartboost().setDelegate(null);
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
                mInterstitialListener.onAdLoaded();
            }
            
            @Override
            public void didFailToLoadInterstitial(String location) {
                Log.d("MoPub", "Chartboost interstitial ad failed to load.");
                mInterstitialListener.onAdFailed();
            }
            
            @Override
            public void didDismissInterstitial(String location) {
                // Note that this method is fired before didCloseInterstitial and didClickInterstitial.
                Log.d("MoPub", "Chartboost interstitial ad dismissed.");
                mInterstitialListener.onDismissInterstitial();
            }
            
            @Override
            public void didCloseInterstitial(String location) {
            }
            
            @Override
            public void didClickInterstitial(String location) {
                Log.d("MoPub", "Chartboost interstitial ad clicked.");
                mInterstitialListener.onClick();
            }
            
            @Override
            public void didShowInterstitial(String location) {
                Log.d("MoPub", "Chartboost interstitial ad shown.");
                mInterstitialListener.onShowInterstitial();
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
