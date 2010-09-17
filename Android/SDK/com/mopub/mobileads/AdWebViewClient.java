package com.mopub.mobileads;

import java.io.IOException;

import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;

import android.content.Intent;
import android.net.Uri;
import android.provider.Settings.Secure;
import android.util.Log;
import android.webkit.WebView;
import android.webkit.WebViewClient;

class AdWebViewClient extends WebViewClient {
	private static final String BASE_ACLK_URL = "http://www.mopub.com/m/aclk";
	private AdView adView;
	private String mUri;
	
	AdWebViewClient(AdView adView) {
		this.adView = adView;
	}
	
	@Override
	public boolean shouldOverrideUrlLoading(WebView view, String url) {
		Log.i("url", url);
		if (url.startsWith("http://www.mopub-inc.com")) {
			view.loadUrl(url);
			return true;
		}

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
		mUri = sz.toString();
		
		// Log the request asynchronously
		Thread trackThread = new Thread(mTrackRunnable);
		trackThread.start();
		
		// and fire off a system wide intent
		adView.getContext().startActivity(new Intent(android.content.Intent.ACTION_VIEW, Uri.parse(url)));
		return true;
	}
	
    Runnable mTrackRunnable = new Runnable() {
        public void run() {          		
    		Log.i("aclk", mUri);

        	HttpClient httpclient = new DefaultHttpClient();  
        	HttpGet httpget = new HttpGet(mUri);  
        	
    		try {
    			httpclient.execute(httpget);  
    		} catch (IOException e) {
    		}
        }
    };	
}
