/*
 * Copyright (c) 2011, MoPub Inc.
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
import android.util.Log;
import android.view.Gravity;
import android.view.View;
import android.widget.FrameLayout;

import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONTokener;

import com.millennialmedia.android.MMAdView;
import com.millennialmedia.android.MMAdView.MMAdListener;
import com.millennialmedia.android.MMAdViewSDK;
import com.mopub.mobileads.MoPubView;

import java.lang.ref.WeakReference;

public class MillennialAdapter extends BaseAdapter implements MMAdListener {

    private MMAdView 					mAdView;
    private MoPubView					mMoPubView;
    private String 						mParams;

    // MMAdListener should use a WeakReference to the activity.
    // From: http://wiki.millennialmedia.com/index.php/Android#Listening_for_Ad_Events
    private WeakReference<Activity>		mActivityReference;

    public MillennialAdapter(MoPubView view, String params) {
        this.mMoPubView = view;
        this.mActivityReference = new WeakReference<Activity>((Activity)view.getContext());
        this.mParams = params;
    }

    @Override
    public void loadAd() {
        Activity activity = mActivityReference.get();
        if (mMoPubView == null || activity == null) {
            return;
        }

        mAdView = new MMAdView(activity, "", MMAdView.BANNER_AD_TOP, MMAdView.REFRESH_INTERVAL_OFF);
        mAdView.setId(MMAdViewSDK.DEFAULT_VIEWID);

        // The following parameters are required. Fail if they aren't set.
        JSONObject object; 
        String pubId;
        try { 
            object = (JSONObject) new JSONTokener(mParams).nextValue(); 
            pubId = object.getString("adUnitID");
        } catch (JSONException e) { 
            mMoPubView.adFailed(); 
            return; 
        }

        mAdView.setApid(pubId);
        mAdView.setListener(this);
        Log.d("MoPub", "Loading Millennial ad...");

        mAdView.setVisibility(View.INVISIBLE);
        mAdView.callForAd();
    }

    @Override
    public void invalidate() {
        mMoPubView = null;
    }

    @Override
    public void MMAdFailed(MMAdView adview)	{
        Log.d("MoPub", "Millennial failed. Trying another");
        if (mMoPubView != null) { 
            mMoPubView.loadFailUrl(); 
        }
    }

    @Override
    public void MMAdReturned(MMAdView adview) {
        Activity activity = mActivityReference.get();
        if (activity != null) {
            activity.runOnUiThread(new MMRunnable(mMoPubView, adview));
        }
    }

    @Override
    public void MMAdClickedToNewBrowser(MMAdView adview) {
        Log.d("MoPub", "Millennial clicked");
        if (mMoPubView != null) { 
            mMoPubView.registerClick(); 
        } 
    }

    @Override
    public void MMAdClickedToOverlay(MMAdView adview) {
        Log.d("MoPub", "Millennial clicked");
        if (mMoPubView != null) { 
            mMoPubView.registerClick(); 
        } 
    }

    @Override
    public void MMAdOverlayLaunched(MMAdView adview) {
        // Nothing needs to happen.
    }

    @Override
    public void MMAdRequestIsCaching(MMAdView adview) {
        // Nothing needs to happen.
    }

    private class MMRunnable implements Runnable {
        private MoPubView mMoPubView;
        private MMAdView mAdView;

        public MMRunnable(MoPubView view, MMAdView adView) {
            mMoPubView = view;
            mAdView = adView;
        }

        public void run() {
            if (mMoPubView != null && mAdView != null) {
                mMoPubView.removeAllViews();
                mAdView.setVisibility(View.VISIBLE);
                mAdView.setHorizontalScrollBarEnabled(false);
                mAdView.setVerticalScrollBarEnabled(false);
                FrameLayout.LayoutParams layoutParams = new FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.WRAP_CONTENT, 
                        FrameLayout.LayoutParams.WRAP_CONTENT);
                layoutParams.gravity = Gravity.CENTER_HORIZONTAL | Gravity.CENTER_VERTICAL;
                mMoPubView.addView(mAdView, layoutParams);
                mMoPubView.adLoaded(); 
            }
        }
    }
}