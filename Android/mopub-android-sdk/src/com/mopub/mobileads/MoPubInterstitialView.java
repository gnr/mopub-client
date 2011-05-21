package com.mopub.mobileads;

import android.app.Dialog;
import android.content.Context;
import android.graphics.Color;
import android.util.Log;
import android.view.Gravity;
import android.widget.LinearLayout;

public class MoPubInterstitialView extends MoPubView {

	public interface OnInterstitialLoadedListener {
        public void OnInterstitialLoaded(MoPubInterstitialView m);
    }

    public interface OnInterstitialFailedListener {
        public void OnInterstitialFailed(MoPubInterstitialView m);
    }
    
    public interface OnInterstitialClickedListener {
    	public void OnInterstitialClicked(MoPubInterstitialView m);
    }
	
	private boolean mReady;
	private Dialog mDialog;
	private OnInterstitialLoadedListener mOnInterstitialLoadedListener;
	private OnInterstitialFailedListener mOnInterstitialFailedListener;
	private OnInterstitialClickedListener mOnInterstitialClickedListener;
	
	public MoPubInterstitialView(Context context) {
		super(context);
		
		LinearLayout layout = new LinearLayout(context);
		layout.setLayoutParams(new LinearLayout.LayoutParams(LinearLayout.LayoutParams.FILL_PARENT, 
				LinearLayout.LayoutParams.FILL_PARENT, Gravity.CENTER));
		layout.setOrientation(LinearLayout.VERTICAL);
		layout.setBackgroundColor(Color.BLACK);
		
		this.setOnAdLoadedListener(new OnAdLoadedListener() {
			public void OnAdLoaded(MoPubView m) {
				Log.i("mopub", "interstitial loaded");
				mReady = true;
				interstitialLoaded();
			}
		});
		this.setOnAdFailedListener(new OnAdFailedListener() {
			public void OnAdFailed(MoPubView m) {
				Log.i("mopub", "interstitial failed to load");
				mReady = false;
				interstitialFailed();
			}
		});
		this.setOnAdClickedListener(new OnAdClickedListener() {
			public void OnAdClicked(MoPubView m) {
				mDialog.dismiss();
			}
		});
		layout.addView(this, new LinearLayout.LayoutParams(
				LinearLayout.LayoutParams.FILL_PARENT, 
				LinearLayout.LayoutParams.FILL_PARENT, 
				Gravity.CENTER));
		
		mDialog = new Dialog(context, android.R.style.Theme_Translucent_NoTitleBar_Fullscreen);
		mDialog.setContentView(layout);
	}

	public void loadAd() {
		super.loadAd();
	}
	
	public void show() {
		mDialog.show();
	}
	
	public boolean isReady() {
		return mReady;
	}
	
	public void setOnInterstitialLoadedListener(OnInterstitialLoadedListener listener) {
		mOnInterstitialLoadedListener = listener;
    }

	public void setOnInterstitialFailedListener(OnInterstitialFailedListener listener) {
		mOnInterstitialFailedListener = listener;
    }
	
	public void setOnInterstitialClickedListener(OnInterstitialClickedListener listener) {
		mOnInterstitialClickedListener = listener;
    }
	
	public void interstitialLoaded() {
		mOnInterstitialLoadedListener.OnInterstitialLoaded(this);
	}
	
	public void interstitialFailed() {
		mOnInterstitialFailedListener.OnInterstitialFailed(this);
	}
	
	public void interstitialClicked() {
		mOnInterstitialClickedListener.OnInterstitialClicked(this);
	}
}
