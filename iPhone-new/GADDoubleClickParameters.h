//
//  GADDoubleClickParameters.h
//  Google Ads iPhone publisher SDK.
//
//  Copyright 2009 Google Inc. All rights reserved.
//

///////////////////////////////////////////////////////////////////////////////
// DoubleClick ad attributes
///////////////////////////////////////////////////////////////////////////////

// Keyname (required). Example site/zone;kw=keyword;key=value;sz=300x50
extern NSString* const kGADDoubleClickKeyname;  // NSString

// Size profile. 'xl' - extra large. 'l' - large. 'm' - medium. 's' - small.
// 't' - text. Defaults to 'xl'.
extern NSString* const kGADDoubleClickSizeProfile;  // NSString

// Background color (used if the ad creative is smaller than the GADAdSize).
// Defaults to FFFFFF.
extern NSString* const kGADDoubleClickBackgroundColor;  // NSString

// Keyword for AdSense requests via DoubleClick for Publishers (DFP).
extern NSString* const kGADDoubleClickAdSenseKeyword;  // NSString

// Client-side impression tracking (csit parameter in URL request).
// Defaults to NO.
extern NSString* const kGADDoubleClickImpressionTracking;  // NSNumber (boolean)

// Forecasting (forecast parameter in URL request)
// Defaults to NO.
extern NSString* const kGADDoubleClickForecast;  // NSNumber (boolean)

// Frequency capping. Pass non-PII (Personally Identifiable Information) unique
// identifier (u in URL request).
// Defaults to "".
extern NSString* const kGADDoubleClickFrequencyCap;  // NSString

// Clickable Area. 'i' - Image only. 'n' - None (c parameter in URL request).
// Defaults to "i".
extern NSString* const kGADDoubleClickClickableArea;  // NSString
