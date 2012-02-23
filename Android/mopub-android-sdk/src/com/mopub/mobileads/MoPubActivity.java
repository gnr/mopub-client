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

import android.app.Activity;
import android.content.res.Configuration;
import android.graphics.drawable.StateListDrawable;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.Window;
import android.view.WindowManager;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.RelativeLayout;

import com.mopub.mobileads.MoPubView.OnAdLoadedListener;

public class MoPubActivity extends Activity implements OnAdLoadedListener {
    public static final int MOPUB_ACTIVITY_NO_AD = 1234;
    private static final float CLOSE_BUTTON_SIZE_DP = 50.0f;
    private static final float CLOSE_BUTTON_PADDING_DP = 8.0f;

    private MoPubView mMoPubView;
    private RelativeLayout mLayout;
    private ImageView mCloseButton;

    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        requestWindowFeature(Window.FEATURE_NO_TITLE);

        String adUnitId = getIntent().getStringExtra("com.mopub.mobileads.AdUnitId");
        String keywords = getIntent().getStringExtra("com.mopub.mobileads.Keywords");
        String clickthroughUrl = getIntent().getStringExtra("com.mopub.mobileads.ClickthroughUrl");
        String source = getIntent().getStringExtra("com.mopub.mobileads.Source");
        int timeout = getIntent().getIntExtra("com.mopub.mobileads.Timeout", 0);

        if (adUnitId == null) {
            throw new RuntimeException("AdUnitId isn't set in " +
                    "com.mopub.mobileads.MoPubActivity");
        }

        mMoPubView = new MoPubView(this);
        mMoPubView.setAdUnitId(adUnitId);
        mMoPubView.setKeywords(keywords);
        mMoPubView.setClickthroughUrl(clickthroughUrl);
        mMoPubView.setTimeout(timeout);
        mMoPubView.setOnAdLoadedListener(this);
        
        if (source != null) {
            source = sourceWithImpressionTrackingDisabled(source);
            mMoPubView.loadHtmlString(source);
        }

        getWindow().addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
        mLayout = new RelativeLayout(this);

        final RelativeLayout.LayoutParams adViewLayout = new RelativeLayout.LayoutParams(
                RelativeLayout.LayoutParams.FILL_PARENT, RelativeLayout.LayoutParams.WRAP_CONTENT);
        adViewLayout.addRule(RelativeLayout.CENTER_IN_PARENT);
        mLayout.addView(mMoPubView, adViewLayout);

        StateListDrawable states = new StateListDrawable();
        states.addState(new int[] {-android.R.attr.state_pressed},
                getResources().getDrawable(R.drawable.close_button_normal));
        states.addState(new int[] {android.R.attr.state_pressed},
                getResources().getDrawable(R.drawable.close_button_pressed));
        mCloseButton = new ImageButton(this);
        mCloseButton.setImageDrawable(states);
        mCloseButton.setBackgroundDrawable(null);
        mCloseButton.setOnClickListener(new OnClickListener() {
            public void onClick(View v) {
                MoPubActivity.this.finish();
            }
        });
        
        final float scale = getResources().getDisplayMetrics().density;
        int buttonSize = (int) (CLOSE_BUTTON_SIZE_DP * scale + 0.5f);
        int buttonPadding = (int) (CLOSE_BUTTON_PADDING_DP * scale + 0.5f);
        RelativeLayout.LayoutParams buttonLayout = new RelativeLayout.LayoutParams(
                buttonSize, buttonSize);
        buttonLayout.addRule(RelativeLayout.ALIGN_PARENT_RIGHT);
        buttonLayout.setMargins(buttonPadding, 0, buttonPadding, 0);
        mLayout.addView(mCloseButton, buttonLayout);

        setContentView(mLayout);
    }
    
    @Override
    public void onConfigurationChanged(Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
    }
    
    @Override
    protected void onDestroy() {
        mMoPubView.destroy();
        mLayout.removeAllViews();
        super.onDestroy();
    }
    
    private String sourceWithImpressionTrackingDisabled(String source) {
        // TODO: Temporary fix. Disables impression tracking by renaming the pixel tracker's URL.
        return source.replaceAll("http://ads.mopub.com/m/imp", "mopub://null");
    }

    public void onAdLoaded(MoPubView m) {
        m.adAppeared();
    }
}
