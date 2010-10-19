package com.mopub.mobileads;

import android.content.Context;
import android.location.Location;
import android.util.AttributeSet;
import android.util.Log;
import android.view.Gravity;
import android.widget.FrameLayout;

import com.mopub.mobileads.adapters.MoPubAdapter;
import com.mopub.mobileads.util.MoPubUtil;

public class MoPubView extends FrameLayout {

	public interface OnAdLoadedListener {
		public void OnAdLoaded(MoPubView m);
	}

	public interface OnAdFailedListener {
		public void OnAdFailed(MoPubView m);
	}

	public interface OnAdClosedListener {
		public void OnAdClosed(MoPubView m);
	}

	private AdView	mAdView = null;
	private OnAdLoadedListener  mOnAdLoadedListener = null;
	private OnAdFailedListener  mOnAdFailedListener = null;
	private OnAdClosedListener  mOnAdClosedListener = null;

	public MoPubView(Context context) {
		super(context);
		init(context, null);
	}

	public MoPubView(Context context, AttributeSet attrs) {
		super(context, attrs);
		init(context, attrs);
	}

	private void init(Context context, AttributeSet attrs) {
		mAdView = new AdView(context, this);
		final FrameLayout.LayoutParams layoutParams = new FrameLayout.LayoutParams(
				320, FrameLayout.LayoutParams.WRAP_CONTENT, Gravity.CENTER);
		addView(mAdView, layoutParams);
	}

	public void loadAd() {
		mAdView.loadAd();
	}

	public void loadNativeAd(int type) {
		removeAllViews();
		// TODO: Instead of failing, try to load next ad type in auction
		try {
			MoPubAdapter.loadAd(this, type);
		} catch (Throwable e) {
			Log.e(MoPubUtil.TAG, e.getMessage());
			adFailed();
		}
	}

	public void setAdUnitId(String adUnitId) {
		mAdView.setAdUnitId(adUnitId);
	}

	public void setKeywords(String keywords) {
		mAdView.setKeywords(keywords);
	}

	public void setLocation(Location location) {
		mAdView.setLocation(location);
	}

	public void setTimeout(int milliseconds) {
		mAdView.setTimeout(milliseconds);
	}

	public void adLoaded() {
		if (mOnAdLoadedListener != null)
			mOnAdLoadedListener.OnAdLoaded(this);
	}

	public void adFailed() {
		if (mOnAdFailedListener != null)
			mOnAdFailedListener.OnAdFailed(this);
	}

	public void adClosed() {
		if (mOnAdClosedListener != null)
			mOnAdClosedListener.OnAdClosed(this);
	}

	public void setOnAdLoadedListener(OnAdLoadedListener listener) {
		mOnAdLoadedListener = listener;
	}

	public void setOnAdFailedListener(OnAdFailedListener listener) {
		mOnAdFailedListener = listener;
	}

	public void setOnAdClosedListener(OnAdClosedListener listener) {
		mOnAdClosedListener = listener;
	}
}