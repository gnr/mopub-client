package com.highnotenetworks.mobileads;

import android.content.Intent;
import android.net.Uri;
import android.provider.Settings.Secure;
import android.util.Log;
import android.webkit.WebView;
import android.webkit.WebViewClient;

class AdWebViewClient extends WebViewClient {
	private static final String BASE_ACLK_URL = "http://www.highnotenetworks.com/m/aclk";
	private AdView adView;
	
	AdWebViewClient(AdView adView) {
		this.adView = adView;
	}
	
	@Override
	public boolean shouldOverrideUrlLoading(WebView view, String url) {
		// Route the ad click through our backend for tracking purposes
		StringBuilder sz = new StringBuilder(BASE_ACLK_URL);
		sz.append("?v=1&id=" + this.adView.getPublisherId());
		sz.append("&udid=" + System.getProperty(Secure.ANDROID_ID));
		if (this.adView.getKeywords() != null) {
			sz.append("&q=" + Uri.encode(adView.getKeywords()));
		}
		if (this.adView.getLocation() != null) {
			sz.append("&ll=" + (this.adView.getLocation().getLatitudeE6() / 1000000.0) + "," + (this.adView.getLocation().getLongitudeE6() / 1000000.0));
		}
		sz.append("&r=" + Uri.encode(url));
		
		// and fire off a system wide intent
		String uri = sz.toString();
		Log.i("aclk", uri);
		adView.getContext().startActivity(new Intent(android.content.Intent.ACTION_VIEW, Uri.parse(uri)));
		return true;
	}
}
