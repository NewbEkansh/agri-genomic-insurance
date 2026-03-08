import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
    Locale('kn'),
    Locale('ml'),
    Locale('mr'),
    Locale('pa'),
    Locale('ta'),
    Locale('te')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'YieldShield'**
  String get appTitle;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alerts;

  /// No description provided for @payouts.
  ///
  /// In en, this message translates to:
  /// **'Payouts'**
  String get payouts;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @ndviScore.
  ///
  /// In en, this message translates to:
  /// **'NDVI Score'**
  String get ndviScore;

  /// No description provided for @soilMoisture.
  ///
  /// In en, this message translates to:
  /// **'Soil Moisture'**
  String get soilMoisture;

  /// No description provided for @cropHealth.
  ///
  /// In en, this message translates to:
  /// **'Crop Health'**
  String get cropHealth;

  /// No description provided for @policyStatus.
  ///
  /// In en, this message translates to:
  /// **'Policy Status'**
  String get policyStatus;

  /// No description provided for @claimPayout.
  ///
  /// In en, this message translates to:
  /// **'Claim Payout'**
  String get claimPayout;

  /// No description provided for @poolBalance.
  ///
  /// In en, this message translates to:
  /// **'Pool Balance'**
  String get poolBalance;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @namaste.
  ///
  /// In en, this message translates to:
  /// **'Namaste'**
  String get namaste;

  /// No description provided for @crop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get crop;

  /// No description provided for @insured.
  ///
  /// In en, this message translates to:
  /// **'Insured'**
  String get insured;

  /// No description provided for @farmId.
  ///
  /// In en, this message translates to:
  /// **'Farm ID'**
  String get farmId;

  /// No description provided for @aiAssessment.
  ///
  /// In en, this message translates to:
  /// **'AI Assessment'**
  String get aiAssessment;

  /// No description provided for @payoutTriggered.
  ///
  /// In en, this message translates to:
  /// **'⚡ Payout Triggered!'**
  String get payoutTriggered;

  /// No description provided for @diseaseDetected.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Disease Detected'**
  String get diseaseDetected;

  /// No description provided for @diseaseAlerts.
  ///
  /// In en, this message translates to:
  /// **'Disease Alerts'**
  String get diseaseAlerts;

  /// No description provided for @noActiveAlerts.
  ///
  /// In en, this message translates to:
  /// **'No Active Alerts'**
  String get noActiveAlerts;

  /// No description provided for @cropsHealthy.
  ///
  /// In en, this message translates to:
  /// **'Your crops are healthy!'**
  String get cropsHealthy;

  /// No description provided for @aiConfidenceScore.
  ///
  /// In en, this message translates to:
  /// **'AI Confidence Score'**
  String get aiConfidenceScore;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidence;

  /// No description provided for @threshold.
  ///
  /// In en, this message translates to:
  /// **'Threshold: 85%'**
  String get threshold;

  /// No description provided for @autoPayoutTriggered.
  ///
  /// In en, this message translates to:
  /// **'AUTO-PAYOUT TRIGGERED'**
  String get autoPayoutTriggered;

  /// No description provided for @belowThreshold.
  ///
  /// In en, this message translates to:
  /// **'BELOW THRESHOLD'**
  String get belowThreshold;

  /// No description provided for @payoutDetails.
  ///
  /// In en, this message translates to:
  /// **'Payout Details'**
  String get payoutDetails;

  /// No description provided for @payoutPercent.
  ///
  /// In en, this message translates to:
  /// **'Payout %'**
  String get payoutPercent;

  /// No description provided for @detected.
  ///
  /// In en, this message translates to:
  /// **'Detected'**
  String get detected;

  /// No description provided for @oracle.
  ///
  /// In en, this message translates to:
  /// **'Oracle'**
  String get oracle;

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auto;

  /// No description provided for @bedrockAnalysis.
  ///
  /// In en, this message translates to:
  /// **'🤖 AWS Bedrock Analysis'**
  String get bedrockAnalysis;

  /// No description provided for @automaticPayout.
  ///
  /// In en, this message translates to:
  /// **'⚡ Automatic payout triggered'**
  String get automaticPayout;

  /// No description provided for @manualReview.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Manual review required'**
  String get manualReview;

  /// No description provided for @payoutHistory.
  ///
  /// In en, this message translates to:
  /// **'Payout History'**
  String get payoutHistory;

  /// No description provided for @totalPayouts.
  ///
  /// In en, this message translates to:
  /// **'Total Payouts'**
  String get totalPayouts;

  /// No description provided for @totalEthReceived.
  ///
  /// In en, this message translates to:
  /// **'Total ETH Received'**
  String get totalEthReceived;

  /// No description provided for @noPayoutsYet.
  ///
  /// In en, this message translates to:
  /// **'No payouts yet'**
  String get noPayoutsYet;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @fullPayout.
  ///
  /// In en, this message translates to:
  /// **'FULL PAYOUT'**
  String get fullPayout;

  /// No description provided for @txHashCopied.
  ///
  /// In en, this message translates to:
  /// **'TX hash copied!'**
  String get txHashCopied;

  /// No description provided for @couldNotOpenEtherscan.
  ///
  /// In en, this message translates to:
  /// **'Could not open Etherscan'**
  String get couldNotOpenEtherscan;

  /// No description provided for @walletAddress.
  ///
  /// In en, this message translates to:
  /// **'Wallet Address'**
  String get walletAddress;

  /// No description provided for @walletCopied.
  ///
  /// In en, this message translates to:
  /// **'Wallet address copied!'**
  String get walletCopied;

  /// No description provided for @farmDetails.
  ///
  /// In en, this message translates to:
  /// **'Farm Details'**
  String get farmDetails;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @insurancePolicy.
  ///
  /// In en, this message translates to:
  /// **'Insurance Policy'**
  String get insurancePolicy;

  /// No description provided for @contract.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get contract;

  /// No description provided for @network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get network;

  /// No description provided for @payoutTrigger.
  ///
  /// In en, this message translates to:
  /// **'Payout Trigger'**
  String get payoutTrigger;

  /// No description provided for @aiTrigger.
  ///
  /// In en, this message translates to:
  /// **'AI ≥ 85% confidence'**
  String get aiTrigger;

  /// No description provided for @sepoliaTestnet.
  ///
  /// In en, this message translates to:
  /// **'Sepolia Testnet'**
  String get sepoliaTestnet;

  /// No description provided for @insuredAmount.
  ///
  /// In en, this message translates to:
  /// **'Insured Amount'**
  String get insuredAmount;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'bn',
        'en',
        'gu',
        'hi',
        'kn',
        'ml',
        'mr',
        'pa',
        'ta',
        'te'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'ml':
      return AppLocalizationsMl();
    case 'mr':
      return AppLocalizationsMr();
    case 'pa':
      return AppLocalizationsPa();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
