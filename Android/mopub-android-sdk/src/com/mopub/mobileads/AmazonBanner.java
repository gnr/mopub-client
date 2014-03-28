package com.mopub.mobileads;

import java.util.Map;

import android.app.Activity;
import android.util.Log;

import com.amazon.device.ads.AdError;
import com.amazon.device.ads.AdLayout;
import com.amazon.device.ads.AdListener;
import com.amazon.device.ads.AdProperties;
import com.amazon.device.ads.AdSize;
import com.amazon.device.ads.AdTargetingOptions;

public class AmazonBanner extends CustomEventBanner implements AdListener {
    private CustomEventBanner.Listener mBannerListener;
    private AdLayout mAmazonAd;

    /*
     * Abstract methods from CustomEventBanner
     */
    @Override
	public void loadAd(Activity activity, CustomEventBanner.Listener bannerListener,
                              Map<String, Object> localExtras, Map<String, String> serverExtras) {
        mBannerListener = bannerListener;

        Log.d("AmazonBanner", "loadAd()");
        mAmazonAd = new AdLayout(activity, AdSize.SIZE_320x50);
        mAmazonAd.setListener(this);
        mAmazonAd.loadAd(new AdTargetingOptions());
		mBannerListener.setAdContentView(mAmazonAd);
    }

    @Override
	public void onInvalidate() {
        Log.d("AmazonBanner", "onInvalidate()");
//        mAmazonAd.destroy();
//        mAmazonAd = null;
    }

    /*
     * Methods from Amazon's AdListener
     */
	@Override
	public void onAdCollapsed(AdLayout view) {
        Log.d("AmazonBanner", "onAdCollapsed()");
	}

	@Override
	public void onAdExpanded(AdLayout view) {
        Log.d("AmazonBanner", "onAdExpanded()");
	}

	@Override
	public void onAdFailedToLoad(AdLayout view, AdError error) {
		Log.d("AmazonBanner", "onAdFailedToLoad()");
		mBannerListener.onAdFailed();
	}

	@Override
	public void onAdLoaded(AdLayout view, AdProperties adProperties) {
        Log.d("AmazonBanner", "onAdLoaded()");
		mBannerListener.onAdLoaded();
	}
}