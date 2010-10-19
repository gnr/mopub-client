package com.mopub.mobileads.adapters;

import android.view.Gravity;
import android.widget.FrameLayout;

import com.google.ads.GoogleAdView;
import com.google.ads.AdViewListener;
import com.google.ads.AdSenseSpec;
import com.google.ads.AdSenseSpec.AdType;
import com.mopub.mobileads.MoPubView;

public class AdSenseAdapter extends MoPubAdapter implements AdViewListener {
	private GoogleAdView mAdView;

	public AdSenseAdapter(MoPubView bannerAdLayout) {
		super(bannerAdLayout);
	}

	public void loadAd() {
		MoPubView view = mMoPubViewReference.get();
		if(view == null) {
			return;
		}
		
		mAdView = new GoogleAdView(view.getContext());
        final FrameLayout.LayoutParams layoutParams = new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT);
        layoutParams.gravity = Gravity.CENTER_HORIZONTAL | Gravity.CENTER_VERTICAL;
        view.addView(mAdView, layoutParams);

		AdSenseSpec adSenseSpec = new AdSenseSpec("ca-mb-app-pub-7961568476960674") // Specify
		// client ID.
		// (Required)
		.setCompanyName("Abhishek Nath") // Set
		// company
		// name.
		// (Required)
		.setAppName("Topo Maps") // Set
		// application
		// name.
		// (Required)
		.setKeywords("gps") // Specify
		// keywords.
		.setChannel("1364897473") // Set channel
		// ID.
		.setAdType(AdType.TEXT_IMAGE) // Set ad
		// type to
		// Text.
		.setExpandDirection(AdSenseSpec.ExpandDirection.TOP).setAdTestEnabled(false); // Keep

		mAdView.setAdViewListener(this);
		mAdView.showAds(adSenseSpec);
	}

	public void onStartFetchAd() {}

	public void onFinishFetchAd() {}

	public void onClickAd() {}

	public void onAdFetchFailure() {}
}
