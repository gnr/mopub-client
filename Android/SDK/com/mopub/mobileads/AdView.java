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
import java.lang.ref.WeakReference;

import org.apache.http.Header;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.HttpStatus;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.params.BasicHttpParams;
import org.apache.http.params.HttpConnectionParams;
import org.apache.http.params.HttpParams;

import android.content.Context;
import android.location.Location;
import android.location.LocationManager;
import android.net.Uri;
import android.os.Handler;
import android.provider.Settings.Secure;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;
import android.webkit.WebView;

public class AdView extends WebView {

	private String 				mAdUnitId = null;
	private String 				mKeywords = null;
	private String				mUrl = null;
	private String				mClickthroughUrl = null; 
	private String				mRedirectUrl = null; 
	private String				mFailUrl = null; 
	private Location 			mLocation = null;
	private int					mTimeout = -1; // HTTP connection timeout in msec
	
	private Handler				mHandler = null;

	private WeakReference<MoPubView>	mMoPubViewReference;
	private AdWebViewClient 	mWebViewClient = null;

	public AdView(Context context, MoPubView view) {
		super(context);
		
		this.mMoPubViewReference = new WeakReference<MoPubView>(view);
		mHandler = new Handler();
		
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
		mWebViewClient = new AdWebViewClient();
		setWebViewClient(mWebViewClient);
	}

	@Override
	public void loadUrl(String url) {
		mUrl = url;
		if (mUrl.startsWith("javascript:")) {
			super.loadUrl(mUrl);
		}

		Runnable getUrl = new LoadUrlThread(mUrl);
		// Need to run a Handler since it needs to update the UI when done
		mHandler.post(getUrl);
	}

	@Override
	public void reload() {
		loadUrl(mUrl);
	}

	// Have to override loadUrl() in order to get the headers, which
	// MoPub uses to pass control information to the client.  Unfortunately
	// WebView doesn't let us get to the headers...
	private class LoadUrlThread implements Runnable {
		private String mUrl;

		public LoadUrlThread(String url) {
			mUrl = url;
		}

		public void run() {
			try {
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
				HttpGet httpget = new HttpGet(mUrl);
				httpget.addHeader("User-Agent", getSettings().getUserAgentString());
				HttpResponse response = httpclient.execute(httpget);

				if (response.getStatusLine().getStatusCode() != HttpStatus.SC_OK) {
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

				// Handle requests for native SDK ads
				if (atHeader.getValue().toLowerCase().equals("adsense")) {
					Log.i("MoPub","Load AdSense ad");
					MoPubView view = mMoPubViewReference.get();
					if (view != null) {
						Header npHeader = response.getFirstHeader("X-Nativeparams"); 
						if (npHeader != null) { 
							view.loadAdSense(npHeader.getValue()); 
						} 
					}
					return;
				}

				InputStream is = entity.getContent();
				BufferedReader reader = new BufferedReader(new InputStreamReader(is));
				StringBuilder sb = new StringBuilder();

				String line = null;
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
						e.printStackTrace();
					}
				}
				loadDataWithBaseURL(mUrl, sb.toString(),"text/html","utf-8", null);
			}
			catch (Exception e) {
				e.printStackTrace();
				pageFailed();
				return;
			}
		}
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

	public void loadFailUrl() { 
		if (mFailUrl != null) { 
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
				} catch (ClientProtocolException e) { 
				} catch (IOException e) { 
				} 
			} 
		}).start(); 
	}

	public void pageFinished() {
		MoPubView view = mMoPubViewReference.get();
		if (view != null)
			view.adLoaded();
	}

	public void pageFailed() {
		MoPubView view = mMoPubViewReference.get();
		if (view != null)
			view.adFailed();
	}

	public void pageClosed() {
		MoPubView view = mMoPubViewReference.get();
		if (view != null)
			view.adClosed();
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
		if (milliseconds > 0) {
			mTimeout = milliseconds;
		}
	}

	public String getClickthroughUrl() { 
		return mClickthroughUrl; 
	} 

	public String getRedirectUrl() { 
		return mRedirectUrl; 
	} 
}
