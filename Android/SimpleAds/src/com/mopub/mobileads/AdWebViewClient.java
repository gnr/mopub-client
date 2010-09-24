package com.mopub.mobileads;

import android.content.Intent;
import android.net.Uri;
import android.util.Log;
import android.webkit.WebView;
import android.webkit.WebViewClient;

class AdWebViewClient extends WebViewClient {
	private String 	mClickthroughUrl = null;
	
	public void setClickthroughUrl(String url) {
		mClickthroughUrl = url;
	}
	
	@Override
	public boolean shouldOverrideUrlLoading(WebView view, String url) {
		Log.i("url", url);

		// Check if this is a local call
		if (url.startsWith("mopub://")) {
			//TODO: Handle ad callbacks
			return true;
		}

		String uri = url;
		if (mClickthroughUrl != null  && !url.startsWith("http://www.mopub.com")) {
			uri = mClickthroughUrl + "&r=" + Uri.encode(url);
		}
		
		// Log the request asynchronously
		Log.i("aclk", uri);

		// and fire off a system wide intent
		view.getContext().startActivity(new Intent(android.content.Intent.ACTION_VIEW, Uri.parse(uri)));
		return true;
	}
	
	@Override
	public void onPageFinished(WebView view, String url) {
		if (view instanceof AdView) {
			((AdView)view).pageFinished();
		}
	}
}
