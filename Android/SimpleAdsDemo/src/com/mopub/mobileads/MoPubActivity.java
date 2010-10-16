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

import com.mopub.mobileads.MoPubView.OnAdClosedListener;
import com.mopub.mobileads.MoPubView.OnAdFailedListener;
import com.mopub.mobileads.MoPubView.OnAdLoadedListener;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;

public class MoPubActivity extends Activity {
	private MoPubView				mMoPubLayout = null;

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

		mMoPubLayout = new MoPubView(this);
		mMoPubLayout.setAdUnitId(adUnitId);
		if (keywords != null) {
			mMoPubLayout.setKeywords(keywords);
		}
		if (timeout > 0) {
			mMoPubLayout.setTimeout(timeout);
		}

		mMoPubLayout.loadAd();
		mMoPubLayout.setOnAdClosedListener(new OnAdClosedListener() {
			public void OnAdClosed(MoPubView a) {
				setResult(RESULT_OK);
				finish();
			}
		});
		mMoPubLayout.setOnAdLoadedListener(new OnAdLoadedListener() {
			public void OnAdLoaded(MoPubView a) {
				Log.i("mopub","ad loaded");
				setVisible(true);
			}
		});
		mMoPubLayout.setOnAdFailedListener(new OnAdFailedListener() {
			public void OnAdFailed(MoPubView a) {
				Log.i("mopub","ad failed");
				setResult(RESULT_CANCELED);
				finish();
			}
		});

		setContentView(mMoPubLayout);
	}
}
