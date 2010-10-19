package com.mopub.mobileads.adapters;

import java.lang.ref.WeakReference;
import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;

import android.util.Log;

import com.mopub.mobileads.MoPubView;
import com.mopub.mobileads.util.MoPubUtil;

public abstract class MoPubAdapter {
	protected final WeakReference<MoPubView> mMoPubViewReference;

	public MoPubAdapter(MoPubView view) {
		this.mMoPubViewReference = new WeakReference<MoPubView>(view);
	}

	public static void loadAd(MoPubView view, int type) throws Throwable {
		MoPubAdapter adapter = MoPubAdapter.getAdapter(view, type);
		if (adapter != null) {
			adapter.loadAd();
		}
		else {
			throw new Exception("Invalid adapter");
		}
	}

	private static MoPubAdapter getAdapter(MoPubView view, int type) {
		MoPubAdapter adapter = null;
		if (type == MoPubUtil.NATIVE_TYPE_ADSENSE) {
			if (MoPubUtil.DEBUG) Log.d(MoPubUtil.TAG, "Trying AdSense");
			try {
				if (Class.forName("com.google.ads.GoogleAdView") != null) {
					return getNetworkAdapter("com.mopub.mobileads.adapters.AdSenseAdapter", view);
				}
			} catch (ClassNotFoundException e) {
				return null;
			}
		}
		return adapter;
	}

	private static MoPubAdapter getNetworkAdapter(String networkAdapter, MoPubView view) {
		MoPubAdapter adapter = null;

		try {
			@SuppressWarnings("unchecked")
			Class<? extends MoPubAdapter> adapterClass = (Class<? extends MoPubAdapter>) Class.forName(networkAdapter);

			Class<?>[] parameterTypes = new Class[1];
			parameterTypes[0] = MoPubView.class;

			Constructor<? extends MoPubAdapter> constructor = adapterClass.getConstructor(parameterTypes);

			Object[] args = new Object[1];
			args[0] = view;

			adapter = constructor.newInstance(args);
		}
		catch(ClassNotFoundException e) {}
		catch(SecurityException e) {}
		catch(NoSuchMethodException e) {}
		catch(InvocationTargetException e) {}
		catch(IllegalAccessException e) {}
		catch(InstantiationException e) {}

		return adapter;
	}

	public abstract void loadAd();
}
