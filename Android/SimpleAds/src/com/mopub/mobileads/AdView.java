package com.mopub.mobileads;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;

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
	private static final String BASE_AD_URL = "http://www.mopub.com/m/ad";

	private String mAdUnitId;
	private String mClickthroughUrl;
	private String keywords;
	private GeoPoint location;

	private AdWebViewClient webViewClient;

	public AdView(Context context) {
		super(context);
		initAdView(context, null);
	}

	public AdView(Context context, AttributeSet attrs) {
		super(context, attrs);
		initAdView(context, attrs);
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
				mClickthroughUrl = response.getFirstHeader("X-Clickthrough").getValue();
				Log.i("clickthrough url", mClickthroughUrl);
				if (entity != null) {
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
						}
					}
					loadDataWithBaseURL(mUrl, sb.toString(),"text/html","utf-8", null);
				}
			}
			catch (Exception e) {
			}
		}
	}

	private void initAdView(Context context, AttributeSet attrs) {
		this.getSettings().setJavaScriptEnabled(true);

		// set web view client
		this.webViewClient = new AdWebViewClient(this);
		this.setWebViewClient(webViewClient);
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

	public String getKeywords() {
		return keywords;
	}

	public void setKeywords(String keywords) {
		this.keywords = keywords;
	}

	public GeoPoint getLocation() {
		return location;
	}

	public void setLocation(GeoPoint location) {
		this.location = location;
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

}
