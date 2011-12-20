package com.mopub.simpleadsdemo;

import com.mopub.mobileads.MoPubView;
import com.mopub.simpleadsdemo.R;
import com.mopub.mobileads.MoPubView.OnAdFailedListener;
import com.mopub.mobileads.MoPubView.OnAdLoadedListener;
import com.mopub.mobileads.MoPubView.OnAdWillLoadListener;

import android.app.Activity;
import android.content.Context;
import android.os.Bundle;
import android.text.method.ScrollingMovementMethod;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.inputmethod.InputMethodManager;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;

public class ConsoleTab extends Activity {
    private MoPubView mBanner;
    private EditText mSearchText;
    private TextView mConsoleText;

    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.console);

        mBanner = (MoPubView) findViewById(R.id.bannerview);
        mBanner.setAdUnitId(SimpleAdsDemoConstants.PUB_ID_320x50);
        mBanner.setOnAdWillLoadListener(new OnAdWillLoadListener() {
            public void OnAdWillLoad(MoPubView mpv, String url) {
                clearConsole();
                outputLine("Calling MoPub with "+url);
            }
        });
        mBanner.setOnAdLoadedListener(new OnAdLoadedListener() {
            public void OnAdLoaded(MoPubView mpv) {
                outputLine("Ad was loaded. Success.");
                outputLine("Payload = "+mpv.getResponseString());
            }
        });
        mBanner.setOnAdFailedListener(new OnAdFailedListener() {
            public void OnAdFailed(MoPubView mpv) {
                outputLine("Ad did not load.");
                outputLine("Payload = "+mpv.getResponseString());
            }
        });
        mConsoleText = (TextView) findViewById(R.id.consoletext);
        mConsoleText.setMovementMethod(new ScrollingMovementMethod());

        mSearchText = (EditText) findViewById(R.id.searchtext);
        Button mSearchButton = (Button) findViewById(R.id.searchbutton);
        mSearchButton.setOnClickListener(new OnClickListener() {
            public void onClick(View v) {
                InputMethodManager imm
                        = (InputMethodManager)getSystemService(Context.INPUT_METHOD_SERVICE);
                imm.hideSoftInputFromWindow(mSearchText.getWindowToken(), 0);
                mBanner.setKeywords(mSearchText.getText().toString());
                mBanner.loadAd();
            }
        });
    }

    private void clearConsole() {
        mConsoleText.setText("MoPub Ad Loading Console\n========================\n");
        mConsoleText.bringPointIntoView(0);
    }

    private void outputLine(String str) {
        mConsoleText.append(str+"\n");
    }
    
    @Override
    protected void onDestroy() {
        mBanner.destroy();
        super.onDestroy();
    }
}