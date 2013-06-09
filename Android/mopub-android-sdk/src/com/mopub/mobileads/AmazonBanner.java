package com.mopub.mobileads;

import java.util.Map;

import android.content.Context;
import android.util.Log;

import com.amazon.device.ads.AdError;
import com.amazon.device.ads.AdLayout;
import com.amazon.device.ads.AdLayout.AdSize;
import com.amazon.device.ads.AdListener;
import com.amazon.device.ads.AdProperties;
import com.amazon.device.ads.AdTargetingOptions;

public class AmazonBanner extends CustomEventBanner implements AdListener {
    private CustomEventBanner.Listener mBannerListener;
    private AdLayout mAmazonAd;

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
        Log.d("AmazonBanner", "loadAd()");
        mAmazonAd = new AdLayout(context, AdSize.AD_SIZE_320x50);
        mAmazonAd.setListener(this);
        mAmazonAd.loadAd(new AdTargetingOptions());
		mBannerListener.setAdContentView(mAmazonAd);
    }

    @Override
	public void onInvalidate() {
        Log.d("AmazonBanner", "onInvalidate()");
        mAmazonAd.destroy();
        mAmazonAd = null;
    }

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