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

import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.HttpStatus;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;

import android.content.Context;
import android.content.SharedPreferences;
import android.provider.Settings.Secure;
import android.util.Log;

public class AdConversionTracker {
	private static final String BASE_AD_HOST = "ads.mopub.com";
	private static final String BASE_AD_HANDLER = "/m/open";
	
	private Context		mContext = null;
	private String		mAppId = null;
	
	public AdConversionTracker() {
	}

	public void reportAppOpen(Context context, String appId) {
		if (context == null || appId == null) {
			return;
		}
		mContext = context;
		mAppId = appId;
		
	    SharedPreferences settings = mContext.getSharedPreferences("mopubSettings", 0);
    	if (settings.getBoolean(appId+" tracked", false) == false) {
    		new Thread(mTrackOpen).start();
    	}
	}

    Runnable mTrackOpen = new Runnable() {
		public void run() {
			StringBuilder sz = new StringBuilder("http://"+BASE_AD_HOST+BASE_AD_HANDLER);
			sz.append("?v=2&id=" + mAppId);
			sz.append("&udid=" + System.getProperty(Secure.ANDROID_ID));
			String url = sz.toString();
			Log.i("mopub", "conversion track: "+url);

			try {
				DefaultHttpClient httpclient = new DefaultHttpClient();
				HttpGet httpget = new HttpGet(url);  
				HttpResponse response = httpclient.execute(httpget);
				
				if (response.getStatusLine().getStatusCode() != HttpStatus.SC_OK) {
					return;
				}

				HttpEntity entity = response.getEntity();
				if (entity == null || entity.getContentLength() == 0) {
					return;
				}
				
				// If we made it here, the request has been tracked
				SharedPreferences.Editor editor = mContext.getSharedPreferences("mopubSettings", 0).edit();
				editor.putBoolean(mAppId+" tracked", true).commit();
				
			} catch (Exception e) {
			}
		}
	};
}
