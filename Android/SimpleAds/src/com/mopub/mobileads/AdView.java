package com.mopub.mobileads;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;

import org.apache.http.Header;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;

import android.content.Context;
import android.net.Uri;
import android.provider.Settings.Secure;
import android.util.AttributeSet;
import android.util.Log;
import android.webkit.WebView;

import com.google.android.maps.GeoPoint;

public class AdView extends WebView {
	
	public interface OnAdLoadedListener {
		public void OnAdLoaded(AdView a);
	}

	private static final String BASE_AD_URL = "http://10.0.2.2:8082/m/ad";

	private String 				mAdUnitId = null;
	private String 				mClickthroughUrl = null;
	private String 				mKeywords = null;
	private GeoPoint 			mLocation = null;

	private AdWebViewClient 	mWebViewClient = null;
	private OnAdLoadedListener  mOnAdLoadedListener = null;

	public AdView(Context context) {
		super(context);
		initAdView(context, null);
	}

	public AdView(Context context, AttributeSet attrs) {
		super(context, attrs);
		initAdView(context, attrs);
	}

	private void initAdView(Context context, AttributeSet attrs) {
		getSettings().setJavaScriptEnabled(true);

		// set web view client
		mWebViewClient = new AdWebViewClient();
		setWebViewClient(mWebViewClient);
	}

	@Override
	public void loadUrl(String url) {
		Runnable getUrl = new LoadUrlThread(url);
		new Thread(getUrl).start();
	}
	
	public class LoadUrlThread implements Runnable {
		private String mUrl;

		public LoadUrlThread(String url) {
			mUrl = url;
		}

		public void run() {
			try {
				DefaultHttpClient httpclient = new DefaultHttpClient();
				HttpGet httpget = new HttpGet(mUrl);  
				HttpResponse response = httpclient.execute(httpget);
				HttpEntity entity = response.getEntity();
				
				if (entity != null) {
					// Get the various header messages
					Header ctHeader = response.getFirstHeader("X-Clickthrough");
					if (ctHeader != null) {
						mClickthroughUrl = ctHeader.getValue();
						Log.i("clickthrough url", mClickthroughUrl);
					}
					else {
						mClickthroughUrl = null;
					}
					
					// If there is no ad, don't bother loading the data
					Header bfHeader = response.getFirstHeader("X-Backfill");
					if (bfHeader != null) {
						if (bfHeader.getValue() == "clear") {
							return;
						}
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
					} finally {
						try {
							is.close();
						} catch (IOException e) {
							e.printStackTrace();
						}
					}
					loadDataWithBaseURL(mUrl, sb.toString(),"text/html","utf-8", null);
				}
			}
			catch (Exception e) {
				e.printStackTrace();
			}
		}
	}

	private String generateAdUrl() {
		StringBuilder sz = new StringBuilder(BASE_AD_URL);
		sz.append("?v=1&id=" + this.mAdUnitId);
		sz.append("&udid=" + System.getProperty(Secure.ANDROID_ID));
		if (this.getKeywords() != null) {
			sz.append("&q=" + Uri.encode(getKeywords()));
		}
		if (this.getLocation() != null) {
			sz.append("&ll=" + (this.getLocation().getLatitudeE6() / 1000000.0) + "," + (this.getLocation().getLongitudeE6() / 1000000.0));
		}
		return sz.toString();
	}

	public void loadAd() {
		String adUrl = generateAdUrl();
		Log.i("ad url", adUrl);
		this.loadUrl(adUrl);
	}
	
	public void pageFinished() {
		if (mOnAdLoadedListener != null) {
			mOnAdLoadedListener.OnAdLoaded(this);
		}
	}

	public String getKeywords() {
		return mKeywords;
	}

	public void setKeywords(String keywords) {
		mKeywords = keywords;
	}

	public GeoPoint getLocation() {
		return mLocation;
	}

	public void setLocation(GeoPoint location) {
		mLocation = location;
	}

	public String getAdUnitId() {
		return mAdUnitId;
	}
	
	public void setAdUnitId(String adUnitId) {
		mAdUnitId = adUnitId;
	}

	public String getClickthroughUrl() {
		return mClickthroughUrl;
	}
	
	public void setOnAdLoadedListener(OnAdLoadedListener listener) {
		mOnAdLoadedListener = listener;
	}
}
