package com.mopub.mobileads;

import android.content.Intent;
import android.net.Uri;
import android.util.Log;
import android.webkit.WebView;
import android.webkit.WebViewClient;

class AdWebViewClient extends WebViewClient {
	private AdView adView;
	
	AdWebViewClient(AdView adView) {
		this.adView = adView;
	}
	
	@Override
	public boolean shouldOverrideUrlLoading(WebView view, String url) {
		Log.i("url", url);

		String uri = ((AdView) view).getClickthroughUrl();
		if (uri != null) {
			uri += "&r=" + Uri.encode(url);
		}
		else {
			uri = url;
		}
		
		// Log the request asynchronously
		Log.i("aclk", uri);

		// and fire off a system wide intent
		adView.getContext().startActivity(new Intent(android.content.Intent.ACTION_VIEW, Uri.parse(uri)));
		return true;
	}
	
	@Override
	public void onPageFinished(WebView view, String url) {
		
	}
}
