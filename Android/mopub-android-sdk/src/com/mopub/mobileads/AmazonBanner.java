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
//        String amazonAppId = "YOUR_AMAZON_APP_ID";
        Log.d("AmazonBanner", "loadAd()");
        mAmazonAd = new AdLayout(context, AdSize.AD_SIZE_320x50);
        mAmazonAd.setListener(this);
        mAmazonAd.loadAd(new AdTargetingOptions());

//        mAmazonAd.refresh();
    }

    @Override
	public void onInvalidate() {
//        mAmazonAd.setListener(this);
        Log.d("AmazonBanner", "onInvalidate()");
    }

	@Override
	public void onAdCollapsed(AdLayout view) {
		// TODO Auto-generated method stub
        Log.d("AmazonBanner", "onAdCollapsed()");
	}

	@Override
	public void onAdExpanded(AdLayout view) {
		// TODO Auto-generated method stub
        Log.d("AmazonBanner", "onAdExpanded()");
	}

	@Override
	public void onAdFailedToLoad(AdLayout view, AdError error) {
		// TODO Auto-generated method stub
//      Log.d("MoPub", "Greystripe banner ad failed to load.");
        Log.d("AmazonBanner", "onAdFailedToLoad()");
      mBannerListener.onAdFailed();
	}

	@Override
	public void onAdLoaded(AdLayout view, AdProperties adProperties) {
        Log.d("AmazonBanner", "onAdLoaded()");
		mBannerListener.onAdLoaded();
		mBannerListener.setAdContentView(mAmazonAd);
	}
}