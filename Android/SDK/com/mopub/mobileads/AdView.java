package com.mopub.mobileads;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.net.Uri;
import android.os.Bundle;
import android.provider.Settings.Secure;
import android.util.AttributeSet;
import android.util.Log;
import android.webkit.WebView;

import com.google.android.maps.GeoPoint;

public class AdView extends WebView {
	private static final String BASE_AD_URL = "http://www.mopub.com/m/ad";
	
	private String publisherId;
	private String keywords;
	private GeoPoint location;
	
	private AdWebViewClient webViewClient;

	public AdView(Context context) {
		super(context);
		initAdView(context);
	}
	
	public AdView(Context context, AttributeSet attrs) {
		super(context, attrs);
		initAdView(context);
	}
	
	private void initAdView(Context context) {
		try {
			ApplicationInfo  ai = context.getPackageManager().getApplicationInfo(context.getPackageName(),
					PackageManager.GET_META_DATA);
			Bundle bundle = ai.metaData;
			publisherId = bundle.getString("MOPUB_PUBLISHER_ID");
		} catch (NameNotFoundException e) { 
			e.printStackTrace(); 
		}

		this.getSettings().setJavaScriptEnabled(true);

		// set web view client
		this.webViewClient = new AdWebViewClient(this);
		this.setWebViewClient(webViewClient);
	}
	
	private String generateAdUrl() {
		StringBuilder sz = new StringBuilder(BASE_AD_URL);
		sz.append("?v=1&id=" + this.publisherId);
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

	public String getPublisherId() {
		return publisherId;
	}
	
	
}
