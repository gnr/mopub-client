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

import java.lang.reflect.Constructor;
import java.lang.reflect.Method;

import android.util.Log;

public abstract class BaseAdapter {

    public abstract void loadAd();

    public static Boolean loadAdForAdapterType(MoPubView view, String params, String type) {
        Class<?> adapterClass = classForAdapterType(type);
        if (adapterClass == null) {
            return false;
        }

        Class<?>[] parameterTypes = new Class[2];
        parameterTypes[0] = MoPubView.class;
        parameterTypes[1] = String.class;

        Object[] args = new Object[2];
        args[0] = view;
        args[1] = params;

        try {
            Constructor<?> constructor = adapterClass.getConstructor(parameterTypes);

            Object nativeAdapter = constructor.newInstance(args);

            Method loadAdMethod = adapterClass.getMethod("loadAd", (Class[]) null);
            loadAdMethod.invoke(nativeAdapter, (Object[]) null);
            return true;
        } catch (Exception e) {
            Log.d("MoPub", "Couldn't create native adapter for type: "+type);
            return false;
        }
    }

    private static String classStringForAdapterType(String type) {
        if (type.equals("admob_native")) {
            return "com.mopub.mobileads.GoogleAdMobAdapter";
        }
        if (type.equals("adsense")) {
            return "com.mopub.mobileads.AdSenseAdapter";
        }

        return null;
    }

    private static Class<?> classForAdapterType(String type) {
        String className = classStringForAdapterType(type);
        if (className == null) {
            Log.d("MoPub", "Couldn't find a handler for this ad type: "+type+"."
                    + " MoPub for Android does not support it at this time.");
            return null;
        }

        try {
            return (Class<?>) Class.forName(className);
        } catch (ClassNotFoundException e) {
            Log.d("MoPub", "Couldn't find "+className+ "class."
                    + " Make sure the project includes the adapter library for "+className+" from the extras folder");
            return null;
        }
    }
}
