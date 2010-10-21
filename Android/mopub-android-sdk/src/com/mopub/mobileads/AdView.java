/*
 * Copyright (c) 2010, MoPub Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * * Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * * Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 *
 * * Neither the name of 'MoPub Inc.' nor the names of its contributors
 *   may be used to endorse or promote products derived from this software
 *   without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package com.mopub.mobileads;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;

import org.apache.http.Header;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.HttpStatus;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.params.BasicHttpParams;
import org.apache.http.params.HttpConnectionParams;
import org.apache.http.params.HttpParams;

import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.location.Location;
import android.location.LocationManager;
import android.net.Uri;
import android.os.AsyncTask;
import android.provider.Settings.Secure;
import android.util.Log;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;

public class AdView extends WebView {

	private String 				mAdUnitId;
	private String 				mKeywords;
	private String				mUrl;
	private String				mClickthroughUrl; 
	private String				mRedirectUrl; 
	private String				mFailUrl; 
	private Location 			mLocation;
	private int					mTimeout = -1; // HTTP connection timeout in msec
	private int					mWidth;
	private int					mHeight;

	private MoPubView			mMoPubView;

	public AdView(Context context, MoPubView view) {
		super(context);

		mMoPubView = view;

		getSettings().setJavaScriptEnabled(true);

		// Prevent user from scrolling the web view since it always adds a margin
		setOnTouchListener(new View.OnTouchListener() {
			public boolean onTouch(View v, MotionEvent event) {
				return(event.getAction() == MotionEvent.ACTION_MOVE);
			}
		});

		// Set background transparent since some ads don't fill the full width
		setBackgroundColor(0);

		// set web view client
		setWebViewClient(new AdWebViewClient());
	}

	// Have to override loadUrl() in order to get the headers, which
	// MoPub uses to pass control information to the client.  Unfortunately
	// Android WebView doesn't let us get to the headers...
	@Override
	public void loadUrl(String url) {
		mUrl = url;
		if (mUrl.startsWith("javascript:")) {
			super.loadUrl(mUrl);
		}

		new LoadUrlTask().execute(mUrl);
	}

	private class LoadUrlTask extends AsyncTask<String, Void, HttpResponse> {
		protected HttpResponse doInBackground(String... urls) {
			return loadAdFromNetwork(urls[0]);
		}
		protected void onPostExecute(HttpResponse response) {
			handleAdFromNetwork(response);
		}
	}

	private HttpResponse loadAdFromNetwork(String url) {
		HttpParams httpParameters = new BasicHttpParams();

		if (mTimeout > 0) {
			// Set the timeout in milliseconds until a connection is established.
			int timeoutConnection = mTimeout;
			HttpConnectionParams.setConnectionTimeout(httpParameters, timeoutConnection);
			// Set the default socket timeout (SO_TIMEOUT) 
			// in milliseconds which is the timeout for waiting for data.
			int timeoutSocket = mTimeout;
			HttpConnectionParams.setSoTimeout(httpParameters, timeoutSocket);
		}

		DefaultHttpClient httpclient = new DefaultHttpClient(httpParameters);
		HttpGet httpget = new HttpGet(url);
		httpget.addHeader("User-Agent", getSettings().getUserAgentString());
		try {
			return httpclient.execute(httpget);
		} catch (Exception e) {
			return null;
		}
	}

	private void handleAdFromNetwork(HttpResponse response) {
		if (response == null || response.getStatusLine().getStatusCode() != HttpStatus.SC_OK) {
			pageFailed();
			return;
		}

		HttpEntity entity = response.getEntity();
		if (entity == null || entity.getContentLength() == 0) {
			pageFailed();
			return;
		}

		// Get the various header messages
		// If there is no ad, don't bother loading the data
		Header atHeader = response.getFirstHeader("X-Adtype");
		if (atHeader == null || atHeader.getValue().equals("clear")) {
			pageFailed();
			return;
		}

		// If we made it this far, an ad has been loaded

		// Redirect if we get an X-Launchpage header so that AdMob clicks work
		Header rdHeader = response.getFirstHeader("X-Launchpage");
		if (rdHeader != null) {
			mRedirectUrl = rdHeader.getValue();
		}
		else {
			mRedirectUrl = null;
		}

		Header ctHeader = response.getFirstHeader("X-Clickthrough");
		if (ctHeader != null) {
			mClickthroughUrl = ctHeader.getValue();
		}
		else {
			mClickthroughUrl = null;
		}

		Header flHeader = response.getFirstHeader("X-Failurl"); 
		if (flHeader != null) { 
			mFailUrl = flHeader.getValue(); 
		} 
		else { 
			mFailUrl = null; 
		}

		Header wHeader = response.getFirstHeader("X-Width");
		Header hHeader = response.getFirstHeader("X-Height");
		if (wHeader != null && hHeader != null) {
			mWidth = Integer.parseInt(wHeader.getValue().trim());
			mHeight = Integer.parseInt(hHeader.getValue().trim());
		} else {
			mWidth = 0;
			mHeight = 0;
		}

		// Handle requests for native SDK ads
		if (atHeader.getValue().toLowerCase().equals("adsense")) {
			Log.i("MoPub","Load AdSense ad");
			Header npHeader = response.getFirstHeader("X-Nativeparams"); 
			if (npHeader != null) { 
				mMoPubView.loadAdSense(npHeader.getValue()); 
				return;
			}
			else {
				pageFailed();
				return;
			}
		}

		StringBuilder sb = new StringBuilder();
		try {
			InputStream is = entity.getContent();

			BufferedReader reader = new BufferedReader(new InputStreamReader(is));

			String line;
			try {
				while ((line = reader.readLine()) != null) {
					sb.append(line + "\n");
				}
			} catch (IOException e) {
				pageFailed();
				return;
			} finally {
				try {
					is.close();
				} catch (IOException e) {
				}
			}

		} catch (Exception e) {
			pageFailed();
			return;
		}
		loadDataWithBaseURL(null, sb.toString(),"text/html","utf-8", null);
	}

	private String generateAdUrl() {
		StringBuilder sz = new StringBuilder("http://"+MoPubView.HOST+MoPubView.AD_HANDLER);
		sz.append("?v=2&id=" + mAdUnitId);
		sz.append("&udid=" + Secure.getString(getContext().getContentResolver(), Secure.ANDROID_ID));

		if (mKeywords != null) {
			sz.append("&q=" + Uri.encode(mKeywords));
		}
		if (mLocation != null) {
			sz.append("&ll=" + mLocation.getLatitude() + "," + mLocation.getLongitude());
		}
		return sz.toString();
	}

	public void loadAd() {
		if (mAdUnitId == null) {
			throw new RuntimeException("AdUnitId isn't set in com.mopub.mobileads.AdView");
		}

		// Get the last location if one hasn't been provided through setLocation()
		// This leaves mLocation = null if no providers are available
		if (mLocation == null) {
			LocationManager lm = (LocationManager) getContext().getSystemService(Context.LOCATION_SERVICE);
			try {
				mLocation = lm.getLastKnownLocation(LocationManager.GPS_PROVIDER);
			} catch (SecurityException e) {
			}
			Location loc_network = null;
			try {
				loc_network= lm.getLastKnownLocation(LocationManager.NETWORK_PROVIDER);
			} catch (SecurityException e) {
			}
			if (mLocation == null)
				mLocation = loc_network;
			else if (loc_network != null && loc_network.getTime() > mLocation.getTime())
				mLocation = loc_network;
		}

		String adUrl = generateAdUrl();
		Log.d("MoPub", "ad url: "+adUrl);
		loadUrl(adUrl);
	}

	@Override
	public void reload() {
		Log.d("MoPub", "Reload ad: "+mUrl);
		loadUrl(mUrl);
	}

	public void loadFailUrl() { 
		if (mFailUrl != null) { 
			Log.d("MoPub", "Loading failover url: "+mFailUrl);
			loadUrl(mFailUrl); 
		} 
		else { 
			pageFailed(); 
		} 
	} 

	public void registerClick() { 
		if (mClickthroughUrl == null) 
			return; 

		new Thread(new Runnable() { 
			public void run () { 
				try { 
					DefaultHttpClient httpclient = new DefaultHttpClient(); 
					HttpGet httpget = new HttpGet(mClickthroughUrl); 
					httpget.addHeader("User-Agent", getSettings().getUserAgentString()); 
					httpclient.execute(httpget); 
				} catch (Exception e) { 
				} 
			} 
		}).start(); 
	}

	public void pageFinished() {
		Log.i("MoPub","pageFinished");
		mMoPubView.removeAllViews();
		FrameLayout.LayoutParams layoutParams = new FrameLayout.LayoutParams(
				//320, FrameLayout.LayoutParams.WRAP_CONTENT, Gravity.CENTER);
				320, 50, Gravity.CENTER);
		mMoPubView.addView(this, layoutParams);
		mMoPubView.adLoaded();
	}

	public void pageFailed() {
		Log.i("MoPub", "pageFailed");
		mMoPubView.adFailed();
	}

	public void pageClosed() {
		mMoPubView.adClosed();
	}

	public String getKeywords() {
		return mKeywords;
	}

	public void setKeywords(String keywords) {
		mKeywords = keywords;
	}

	public Location getLocation() {
		return mLocation;
	}

	public void setLocation(Location location) {
		mLocation = location;
	}

	public String getAdUnitId() {
		return mAdUnitId;
	}

	public void setAdUnitId(String adUnitId) {
		mAdUnitId = adUnitId;
	}

	public void setTimeout(int milliseconds) {
		mTimeout = milliseconds;
	}

	public int getAdWidth() {
		return mWidth;
	}

	public int getAdHeight() {
		return mHeight;
	}

	public String getClickthroughUrl() { 
		return mClickthroughUrl; 
	} 

	public String getRedirectUrl() { 
		return mRedirectUrl; 
	}

	private class AdWebViewClient extends WebViewClient {
		@Override
		public boolean shouldOverrideUrlLoading(WebView view, String url) {
			Log.d("MoPub", "url: "+url);

			// Check if this is a local call
			if (url.startsWith("mopub://")) {
				if (url.equals("mopub://close")) {
					((AdView)view).pageClosed();
				}
				else if (url.equals("mopub://reload")) {
					((AdView)view).reload();
				}
				return true;
			}

			String uri = url;

			String clickthroughUrl = ((AdView)view).getClickthroughUrl(); 
			if (clickthroughUrl != null) { 
				uri = clickthroughUrl + "&r=" + Uri.encode(url); 
			}

			Log.d("MoPub", "click url: "+uri);

			// and fire off a system wide intent
			view.getContext().startActivity(new Intent(android.content.Intent.ACTION_VIEW, Uri.parse(uri)));
			return true;
		}

		@Override
		public void onPageFinished(WebView view, String url) {
			((AdView)view).pageFinished();
		}

		@Override
		public void onPageStarted(WebView view, String url, Bitmap favicon) {
			String redirectUrl = ((AdView)view).getRedirectUrl(); 
			if (redirectUrl != null && url.startsWith(redirectUrl)) { 
				view.stopLoading();
				view.getContext().startActivity(new Intent(android.content.Intent.ACTION_VIEW, Uri.parse(url)));
			}
		}
	}
}
