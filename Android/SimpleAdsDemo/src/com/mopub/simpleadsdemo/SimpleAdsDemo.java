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

package com.mopub.simpleadsdemo;

import com.mopub.mobileads.AdConversionTracker;
import com.mopub.mobileads.AdView;
import com.mopub.mobileads.InterstitialAdActivity;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.inputmethod.InputMethodManager;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;

public class SimpleAdsDemo extends Activity {
	private AdView				mTopAdView = null;
	private AdView				mMidAdView = null;

	private EditText			mSearchText = null;
	private Button				mSearchButton = null;
	private Button				mShowButton = null;

	private final int			INTERSTITIAL_AD_REQUEST = 0;

	/** Called when the activity is first created. */
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.main);

		// Conversion tracking
		new AdConversionTracker().reportAppOpen(this,"agltb3B1Yi1pbmNyDAsSBFNpdGUY2aQGDA");
		
		// Initialize Ad components
		mTopAdView = (AdView) findViewById(R.id.topadview);
		mTopAdView.setAdUnitId("agltb3B1Yi1pbmNyDAsSBFNpdGUY2aQGDA");
		mTopAdView.loadAd();

		mMidAdView = (AdView) findViewById(R.id.middleadview);
		mMidAdView.setAdUnitId("agltb3B1Yi1pbmNyDAsSBFNpdGUY2aQGDA");
		mMidAdView.loadAd();

		mSearchText = (EditText) findViewById(R.id.searchtext);
		mSearchButton = (Button) findViewById(R.id.searchbutton);
		mSearchButton.setOnClickListener(new OnClickListener() {
			public void onClick(View v) {
				InputMethodManager imm = (InputMethodManager)getSystemService(Context.INPUT_METHOD_SERVICE);
				imm.hideSoftInputFromWindow(mSearchText.getWindowToken(), 0);
				mTopAdView.setKeywords(mSearchText.getText().toString());
				mMidAdView.setKeywords(mSearchText.getText().toString());
				mTopAdView.loadAd();
				mMidAdView.loadAd();
			}
		});

		mShowButton = (Button) findViewById(R.id.showbutton);
		mShowButton.setOnClickListener(new OnClickListener() {
			public void onClick(View v) {
				showInterstitialAd();
			}
		});
	}

	public void showInterstitialAd() {
		Intent i = new Intent(this, InterstitialAdActivity.class);
		i.putExtra("com.mopub.mobileads.AdUnitId", "agltb3B1Yi1pbmNyDAsSBFNpdGUY2aQGDA");
		startActivityForResult(i, INTERSTITIAL_AD_REQUEST);
	}
	
	// Listen for results from the interstitial ad
	protected void onActivityResult(int requestCode, int resultCode, Intent data) {
	    switch (requestCode) {
	    case INTERSTITIAL_AD_REQUEST:
	    	// Handle interstitial closed result here if needed.
	    	// This is called immediately before onResume()
	    	if (resultCode == RESULT_CANCELED) {
	    		Toast.makeText(this, "No ad available", Toast.LENGTH_SHORT).show();
	    	}
	    }
	}
}
