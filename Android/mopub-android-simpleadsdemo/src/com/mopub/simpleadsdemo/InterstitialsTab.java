package com.mopub.simpleadsdemo;

import com.mopub.mobileads.MoPubInterstitial;
import com.mopub.mobileads.MoPubInterstitial.MoPubInterstitialListener;
import com.mopub.simpleadsdemo.R;

import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.Toast;

public class InterstitialsTab extends Activity implements MoPubInterstitialListener {

    MoPubInterstitial interstitial;
    
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.interstitials);

        interstitial = new MoPubInterstitial(this, SimpleAdsDemoConstants.PUB_ID_INTERSTITIAL);
        
        Button loadShowButton = (Button) findViewById(R.id.loadshowinterstitial);
        loadShowButton.setOnClickListener(new OnClickListener() {
            public void onClick(View v) {
                showInterstitialAd();
            }
        });
    }

    public void showInterstitialAd() {
        interstitial.setListener(this);
        interstitial.load();
    }

    public void OnInterstitialLoaded() {
    	if (interstitial.isReady()) interstitial.show();
    	else {
    	    Toast.makeText(this, "Interstitial could not be shown. Try reloading.", 
    	            Toast.LENGTH_SHORT).show();
    	}
    }

    public void OnInterstitialFailed() {
        Toast.makeText(this, "No ad available", Toast.LENGTH_SHORT).show();
    }
    
    @Override
    protected void onDestroy() {
        interstitial.destroy();
        super.onDestroy();
    }
}
