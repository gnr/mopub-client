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

import com.mopub.mobileads.AdView.OnAdClosedListener;
import com.mopub.mobileads.AdView.OnAdLoadedListener;

import android.app.Activity;
import android.os.Bundle;

public class InterstitialAdActivity extends Activity {
	private AdView				mInterstitialAdView = null;
	
	/** Called when the activity is first created. */
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		
		setVisible(false);
		
		String adUnitId = getIntent().getStringExtra("com.mopub.mobileads.AdUnitId");
		String keywords = getIntent().getStringExtra("com.mopub.mobileads.Keywords");
		int timeout = getIntent().getIntExtra("com.mopub.mobileads.Timeout", 0);

		if (adUnitId == null) {
			throw new RuntimeException("AdUnitId isn't set in com.mopub.mobileads.InterstitialAdActivity");
		}
		
		
		mInterstitialAdView = new AdView(this);
		mInterstitialAdView.setAdUnitId(adUnitId);
		if (keywords != null) {
			mInterstitialAdView.setKeywords(keywords);
		}
		if (timeout > 0) {
		  mInterstitialAdView.setTimeout(timeout);
		}
 		
		mInterstitialAdView.loadAd();
		mInterstitialAdView.setOnAdClosedListener(new OnAdClosedListener() {
			public void OnAdClosed(AdView a) {
				setResult(RESULT_OK);
				finish();
			}
		});
		mInterstitialAdView.setOnAdLoadedListener(new OnAdLoadedListener() {
			public void OnAdLoaded(AdView a) {
				if (a.hasAd()) {
					setVisible(true);
				}
				else {
					setResult(RESULT_CANCELED);
					finish();
				}
			}
		});

		setContentView(mInterstitialAdView);
	}
}
