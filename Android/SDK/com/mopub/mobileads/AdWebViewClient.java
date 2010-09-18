package com.mopub.mobileads;

import java.io.IOException;
import java.net.URI;

import org.apache.http.HttpResponse;
import org.apache.http.client.RedirectHandler;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.protocol.HttpContext;


import android.content.Intent;
import android.net.Uri;
import android.os.AsyncTask;
import android.provider.Settings.Secure;
import android.util.Log;
import android.webkit.WebView;
import android.webkit.WebViewClient;

class AdWebViewClient extends WebViewClient {
	private static final String BASE_ACLK_URL = "http://www.mopub.com/m/aclk";
	private AdView adView;
	
	AdWebViewClient(AdView adView) {
		this.adView = adView;
	}
	
	@Override
	public boolean shouldOverrideUrlLoading(WebView view, String url) {
		Log.i("url", url);

		// Route the ad click through our backend for tracking purposes
		StringBuilder sz = new StringBuilder(BASE_ACLK_URL);
		sz.append("?v=1&id=" + this.adView.getAdUnitId());
		sz.append("&udid=" + System.getProperty(Secure.ANDROID_ID));
		if (this.adView.getKeywords() != null) {
			sz.append("&q=" + Uri.encode(adView.getKeywords()));
		}
		if (this.adView.getLocation() != null) {
			sz.append("&ll=" + (this.adView.getLocation().getLatitudeE6() / 1000000.0) + "," + (this.adView.getLocation().getLongitudeE6() / 1000000.0));
		}
		sz.append("&r=" + Uri.encode(url));
		
		// Log the request asynchronously
		String uri = sz.toString();
		Log.i("aclk", uri);
		new TrackClickTask().execute(uri);

		// and fire off a system wide intent
		adView.getContext().startActivity(new Intent(android.content.Intent.ACTION_VIEW, Uri.parse(url)));
		return true;
	}
	
	@Override
	public void onPageFinished(WebView view, String url) {
		
	}
	
	 private class TrackClickTask extends AsyncTask<String, Void, Void> {
	     protected Void doInBackground(String... urls) {
	    	 DefaultHttpClient httpclient = new DefaultHttpClient();
	    	 // TODO: Would be really nice if we didn't have to do this redirect weirdness
	    	 httpclient.setRedirectHandler(new RedirectHandler() {
	    		 public URI getLocationURI(HttpResponse response,
	    				 HttpContext context) {
	    			 return null;
	    		 }

	    		 public boolean isRedirectRequested(HttpResponse response,
	    				 HttpContext context) {
	    			 return false;
	    		 }
	    	 });

	    	 HttpGet httpget = new HttpGet(urls[0]);  

	    	 try {
	    		 httpclient.execute(httpget);  
	    	 } catch (IOException e) {
	    	 }
	    	 return null;
	     }
	 }
}
