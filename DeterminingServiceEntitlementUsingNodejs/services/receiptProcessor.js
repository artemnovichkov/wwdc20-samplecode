/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The receipt processor including the main entry point.
*/

/*
 See LICENSE folder for this sample’s licensing information.

 Abstract:
 The receipt processor including the main entry point.
 */

require('dotenv').config();

// Module for signing promotional offers.
const signUtil = require('promo-offer-gen');

// The request framework.
const got = require('got');

// Apple's verify receipt endpoints.
const prodEndpoint = 'https://buy.itunes.apple.com/verifyReceipt';
const sandboxEndpoint = 'https://sandbox.itunes.apple.com/verifyReceipt';

// Import the subscription module for object creation.
const subscription = require('../models/Subscription');

// Add the various subscription objects to construct the response.
// Customize and modify these objects to include data relevant to your
// subscription needs.
const { Subscription } = subscription;
const { subscriptionState } = subscription;
const { subscriptionSubState } = subscription;

// App Receipt Status Codes Enumeration.
// See: https://developer.apple.com/documentation/appstorereceipts/status
// The engine returns this field in the JSON response, responseBody.
// The status code reflects the status of the app receipt as a whole.
// For example, if you send a valid app receipt that contains an expired
// subscription, the response is 0 because the receipt is valid.
const appReceiptStatus = Object.freeze({
  SUCCESS: 0,
  USE_POST: 21000, // The request to the App Store was not made using the HTTP POST request method.
  CANNOT_AUTHENTICATE: 21003, // The data in the receipt-data property was malformed or missing.
  INCORRECT_SECRET: 21004, // The shared secret you provided does not match
  // the shared secret on file for your account.
  SERVER_UNAVAILABLE: 21005, // The receipt server is not currently available.
  EXPIRED_TRANSACTION_RECIEPT: 21006, // Deprecated iOS 6-style receipts are not to be used with this code.
  USE_TEST_ENV: 21007, // This receipt is from the test environment,
  // but it was sent to the production environment for verification.
  USE_PROD_END: 21008, // This receipt is from the production environment,
  // but it was sent to the test environment for verification.
  BAD_ACCESS: 21009, // Internal data access error. Try again later.
  USER_NOT_FOUND: 21010, // The user account cannot be found or has been deleted.
});


// Create an original transaction object.
// Optionally, add custom fields to be returned in the response.
function OriginalTransaction(transaction) {
  this.originalTX = transaction.original_transaction_id;
  this.start = Number(transaction.original_purchase_date_ms);
  this.expiration = Number(transaction.expires_date_ms);
  // Add optional fields.
  // this.upgrades = [];
  // this.downgrades = [];
  // this.crossgrades = [];
  // this.offerID = "";
  // this.signature = "";
  if (process.env.SHOW_TRANSACTIONS === 'true') {
    // Add transaction to transaction array
    this.transactions = [];
  }
  // this.transactions = [];
  this.renewals = 0;
}

// Helper function that returns the index of a specific product ID
// in the subs array. If the product ID is not found in the array, it
// returns the size of array to signal the need to insert
// the new product ID into the array.
function subProductIndex(subs, productID) {
  let i = 0;

  for (i; i < subs.length; i += 1) {
    if (subs[i].product_id === productID) {
      return i;
    }
  }

  return subs.length;
}

// Helper function that returns the index of the original transaction
// in the original transactions array. If the original transaction isn't
// found, the function returns the size of the array.
function originalProductIndex(originalTransactions, originalTX) {
  let i = 0;
  const len = originalTransactions.length;
  for (i, len; i < len; i += 1) {
    if (originalTransactions[i].originalTX === originalTX) {
      return i;
    }
  }

  return originalTransactions.length;
}

// Check the expiration intent and return a value used in the response.
// See https://developer.apple.com/documentation/appstorereceipts/expiration_intent
// for more information about expiration intents.
function applyExpirationIntent(intentCode) {
  switch (intentCode) {
    case '1':
      // The customer voluntarily canceled their subscription.
      return -5.0;
    case '2':
      // Billing error; for example, the customer's payment information
      // was no longer valid.
      return -2.0;
    case '3':
      // The customer did not agree to a price increase.
      return -3.0;
    case '4':
      // The product was not available for purchase at the time of renewal.
      return -4.0;
    case '5':
      // Other error.
      return -5.0;
    default:
      return -2.0;
  }
}


// EXAMPLE
// Optionally, provide the following product information in the response:
// Products that are the downgrade, upgrade, and crossgrade for the
// current product.
// You configure these product mappings in the .env file.
function calcSubMovments(subs) {
  subs.forEach((sub) => {
    if (sub.product_id === process.env.MONTHLY) {
      sub.upgradeTo = process.env.YEARLY;
    } else if (sub.product_id === 'com.example.examplenowmonthly') {
      sub.upgradeTo = 'com.example.exampleyearly';
      sub.downgradeTo = 'com.example.examplebasic';
    }
  });

  return subs;
}


// This function does the bulk of the purchase history processing.
// It sequentially iterates over the purchases and creates custom subscriptions
// objects based on product IDs. The subscription objects are returned in the
// response.
function processLatestReceiptInfo(
  latestReceiptInfo, subscriptions, trialConsumedForGroup, timestamp,
) {
  latestReceiptInfo.forEach((purchase) => {
    const subIndex = subProductIndex(subscriptions, purchase.product_id);

    // Create a new subscription object if it's not present in the array.
    // Otherwise, increment the array.
    if (subIndex === subscriptions.length) {
      const newSub = new Subscription(purchase);
      subscriptions.push(newSub);
    } else {
      const currentTransaction = subscriptions[subIndex];
      // Add this current transaction as another renewal.

      currentTransaction.totalRenewals += 1;
      // Update the expiration date to be the future-most date.
      if (currentTransaction.expiration < Number(purchase.expires_date_ms)) {
        currentTransaction.expiration = Number(purchase.expires_date_ms);
      }
    }

    const sub = subscriptions[subIndex];

    // There can be multiple original transaction IDs for the same product ID.
    // Determine the OTXID this transaction belongs to, or add it to the array
    // as a new transaction.
    const OTXIndex = originalProductIndex(sub.originalTransactions,
      purchase.original_transaction_id);

    if (OTXIndex === sub.originalTransactions.length) {
      // Add the current transaction object to the original transactions array.
      const original = new OriginalTransaction(purchase);

      if (process.env.SHOW_TRANSACTIONS === 'true') {
        // Add the transaction to the transaction array.
        original.transactions.push(purchase);
      }

      sub.originalTransactions.push(original);
    } else {
      const currentOTX = sub.originalTransactions[OTXIndex];
      // Update the expiration date to be the future-most date.
      if (currentOTX.expiration < Number(purchase.expires_date_ms)) {
        currentOTX.expiration = Number(purchase.expires_date_ms);
      }

      if (process.env.SHOW_TRANSACTIONS === 'true') {
        // Add the transaction to the transaction array.
        currentOTX.transactions.push(purchase);
      }

      // Add the current transaction to the renewals count.
      currentOTX.renewals += 1;
    }

    // Included consumed promotional offers as an array because they can be
    // redeemed multiple times.
    if (purchase.promotional_offer_id) {
      sub.consumedPromoOffers = sub.consumedPromoOffers || {};
      sub.consumedPromoOffers[purchase.promotional_offer_id] = (sub.consumedPromoOffers[purchase.promotional_offer_id] || 0) + 1;
    }

    // Update the expiration date to the future-most date.
    // This might be the future-most transaction (active or not).
    if (sub.expiration <= Number(purchase.expires_date_ms)) {
      // Push out the expiration date.
      sub.expiration = Number(purchase.expires_date_ms);

      // Subscription expiration is in the future.  The subscription is active
      // if it's not upgraded or refunded.
      if (timestamp < sub.expiration && !purchase.is_upgraded) {
        // Found an active subscription that is not upgraded.
        // Assume auto-renew is on unless otherwise specified.
        sub.setMainState(subscriptionState.ACTIVE_AUTO_REN_ON);

        // Optionally, pass back an offer ID to indicate the offer that is
        // in effect.
        if (purchase.promotional_offer_id) {
          sub.promotionalOfferId = purchase.promotional_offer_id;
          sub.setSubState(subscriptionSubState.SUB_OFFER);
        }
      }

      // Check the offer type to determine the subscription substate.
      if (purchase.is_in_intro_offer_period === 'true') {
        sub.setSubState(subscriptionSubState.INTRODUCTORY);
      } else if (purchase.is_trial_period === 'true') {
        sub.setSubState(subscriptionSubState.FREE_TRIAL);
      } else if (purchase.promotional_offer_id) {
        sub.setSubState(subscriptionSubState.SUB_OFFER);
      } else {
        sub.setSubState(subscriptionSubState.STANDARD_SUB);
      }

      // Check if the subscription was canceled and update the entitlement value.
      if (purchase.cancellation_reason) {
        // A cancellation reason value of “0” indicates that the transaction was
        // canceled for another reason; for example, if the customer
        // made the purchase accidentally.
        if (purchase.cancellation_reason === '0') {
          // Even if the subscription had a future expiration date, cancel it.
          sub.setMainState(subscriptionState.OTHER_REFUND);
          sub.cancellationDate = Number(purchase.cancellation_date_ms);
        } else {
          // Even if the subcription had a future expiration date, cancel it.
          sub.setMainState(subscriptionState.ISSUE_REFUND);
          sub.cancellationDate = Number(purchase.cancellation_date_ms);
        }

        // Subscription is not active. It was canceled due to an upgrade.
        if (purchase.is_upgraded) {
          sub.setMainState(subscriptionState.UPGRADED);
        }
      }
    }

    // Determine if the the user is eligible for a free trial or introductory
    // offer within the same subscription group.
    // For more information, see Implementing Introductory Offers in Your App.
    if (purchase.is_trial_period === 'true'
        || purchase.is_in_intro_offer_period === 'true') {
      sub.trialConsumed = true;

      // Add the subsription group ID to an array containing all the group IDs
      // for which the user has consumed their introductory offer or free trial.
      const groupID = purchase.subscription_group_identifier;
      trialConsumedForGroup.push(groupID);
    }
  });
}

// Iterates over the pending renewal array to gather insights about
// upcoming subscription renewals.
function processPendingRenewalArray(
  pendingRenewalInfo, subscriptions, timestamp,
) {
  // Check each pending transaction.
  pendingRenewalInfo.forEach((pendingPurch) => {
    const subIndex = subProductIndex(subscriptions, pendingPurch.product_id);
    const sub = subscriptions[subIndex];

    // If the grace period flag is present, use it to determine entitlement.
    // If the grace period is in the future, service is entitled.
    if (timestamp < Number(pendingPurch.grace_period_expires_date_ms)) {
      // Provide service.
      // (Recommended: prompt the user to update their billing information.)
      sub.setMainState(subscriptionState.EXPIRED_IN_GRACE);

      // Uncomment the line below to add a grace-period expiration field
      // instead of overwriting the date.
      // expiration sub.grace_period_expires_date_ms =
      // pendingPurch.grace_period_expires_date_ms

      // Update the expiration date in the response to reflect the grace
      // period expiration.
      sub.expiration = Number(pendingPurch.grace_period_expires_date_ms);

      // Optionally include a billing error message in the response.
      sub.messaging = process.env.BILLING_ERROR;

      // If the subscription is in a grace period or in billing retry,
      // provide service to the downgraded or crossgraded in-app purchase.
      sub.product_id = pendingPurch.auto_renew_product_id;
    } else if (pendingPurch.is_in_billing_retry_period === '1') {
      sub.setMainState(subscriptionState.EXPIRED_IN_RETRY);

      // Example messages you can use for subscriptions in this state.
      sub.messaging = process.env.BILLING_ERROR;
      sub.degraded = process.env.DEGRADED_WARNING;

      // If the subscription is in grace period or billing retry,
      // provide service to the downgraded or crossgraded in-app purchase.
      sub.product_id = pendingPurch.auto_renew_product_id;
    }

    // Optionally, attach a promotional offer you can offer to the customer
    // at the next billing period.
    if (pendingPurch.promotional_offer_id) {
      sub.pendingOffer = pendingPurch.promotional_offer_id;
    }

    // Receipts can't be in grace period or billing-retry while
    // auto-renew is disabled. When auto-renew is disabled, that indicates
    // the customer has voluntarily disabled it.
    if (pendingPurch.auto_renew_status === '0') {
      // Auto-renew is disabled.
      if (!pendingPurch.expiration_intent && timestamp < sub.expiration) {
        // Subscription expiration is in the future with no expiration reason.
        // The customer has disabled auto-renew and will voluntarily churn from
        // the subscription.
        // console.log(sub.entitlementCode);

        // The subscription is active assuming it was not
        // canceled, upgraded, or refunded.
        sub.setMainState(subscriptionState.ACTIVE_AUTO_REN_OFF);
      } else {
        // Auto-renew is disabled but has an expiration intent.
        const expirationCode = applyExpirationIntent(
          pendingPurch.expiration_intent,
        );
        // Apply the expiration reason to the state.
        sub.setMainState(expirationCode);
      }
    } else {
      // The auto-renew status is enabled.
      // Check if the subscription will renew to a different product
      // through a crossgrade or downgrade.
      if (sub.product_id !== pendingPurch.auto_renew_product_id) {
        sub.willRenewTo = pendingPurch.auto_renew_product_id;
      }
    }
  });
}

// Creates an array of subscription objects (purchases)using the latest
// billing data from latestReceiptInfo, and pending billing data
// from pendingRenewalInfobilling.
// The purchases array is retured in the response.
// Extend this function and the response by adding your
// business-relevant insights to each subscription object.
function genSubObjects(
  latestReceiptInfo, pendingRenewalInfo, trialConsumedForGroup,
) {
  const currentDate = new Date();
  const timestamp = currentDate.getTime();

  // Create the array of subscription purchases, grouped by product ID.
  const purchases = [];

  processLatestReceiptInfo(latestReceiptInfo, purchases, trialConsumedForGroup,
    timestamp);

  // Iterate over the pending renewal information to provide
  // critical information about upcoming changes to the billing cycle.
  processPendingRenewalArray(pendingRenewalInfo, purchases, timestamp);

  return purchases;
}

// EXAMPLE
// This is an example of custom business logic.
// For Demo purposes, this code generates an offer for a qualifying product
// that meets the criteria.
function businessActions(body, subs) {
  subs.forEach((sub) => {
    // Example criteria for a "loyalty win-back" offer:
    // If the customer has renewed the subscription N times, is not currently
    // in an offer or trial, but has disabled auto-renew, then make an
    // offer for same product ID.
    // console.log(`Generating offer for ${sub.productIdentifier}`);
    if (sub.totalRenewals >= 7 && sub.product_id === 'com.example.examplenowmonthly'
        && sub.entitlementCode
        === (subscriptionState.ACTIVE_AUTO_REN_OFF + subscriptionSubState.STANDARD_SUB)) {
      // Use loyalty-winback offer.
      const appBundleID = process.env.APP_BUNDLE_ID;
      const offerProductID = 'com.example.premium.yearly';
      const subscriptionOfferID = 'your_offer_id';

      // Must be the same hashed username as the one submitted in the buy request.
      // https://developer.apple.com/documentation/storekit/skmutablepayment/1506088-applicationusername
      const applicationUsername = '8E3DC5F16E13537ADB45FB0F980ACDB6B55839870DBCE7E346E1826F5B0296CA';
      sub.offer = signUtil.generateOffer(appBundleID, offerProductID, subscriptionOfferID, applicationUsername);

      // Optionally, provide the customer with custom messaging.
      // This is a lightweight example. You can include offer strings in
      // the .env file.
      sub.offer.messaging = 'Stick around with this special offer!';
    }
  });

  return subs;
}

// This is the main entry point for processing receipt data in JSON format.
// The endpoints route the receipt JSON to this function.
function processReceiptJSON(body) {
  const latestReceiptInfo = body.latest_receipt_info;
  const pendingRenewalInfo = body.pending_renewal_info;

  // Empty arrays mean the receipt contained no purchase history.
  // Either there are no purchases or you need a newer receipt.
  if (latestReceiptInfo <= 0 && pendingRenewalInfo <= 0) {
    return [];
  }

  // An array containing the subscription group ID's for which the customer is
  // no longer eligible for an intro offer.
  const trialConsumedForGroup = [];

  // Create subscription objects to be returned in the response.
  let subs = genSubObjects(latestReceiptInfo, pendingRenewalInfo,
    trialConsumedForGroup);

  // Optionally, provide a thin response that includes only the subscription products to be unlocked.
  if (process.env.RETURN_ONLY_ACTIONABLE === 'true') {
    subs = subs.filter((sub) => sub.entitlementCode > 0);
  }

  // An example function that you can configure to provide guidance for product
  // upgrade and downgrade in the response.
  if (process.env.SHOW_MOVEMENTS === 'true') {
    subs = calcSubMovments(subs);
  }

  // An example of generating offers for customers with a defined criteria.
  subs = businessActions(body, subs);

  // Respond with subscription data.
  // TODO: Add a custom response for customers without any purchase history.
  return { subscriptions: subs, trialConsumedForGroup };
}

// Fetches the latest receipt from the sandbox endpoint.
async function fetchLatestSandboxReceipt(receipt) {
  const secret = process.env.SHARED_SECRET;

  // Make a fetch request using the sandbox /verifyReceipt endpoint for sandbox receipts.
  const options = {
    url: sandboxEndpoint,
    method: 'POST',
    headers: {
      Accept: 'application/json', 'Accept-Charset': 'utf-8',
    },
    json: {
      'receipt-data': receipt, password: secret,
    },
  };

  try {
    const body = await got.post(options).json();

    if (body.status === appReceiptStatus.SUCCESS) {
      return body;
    }
    //  TODO: Add code to handle failure conditions
    // Depending on the error and the origin of the request,
    // determine whether it's necessary to provide an entitlementCode status.
    // For example, if the entitlementCode attempt is made during a client
    // launch, it may be ideal to fail-over to persisted data, to manually
    // validate, or to retry.
  } catch (error) {
    // TODO: Build error handling and failover support.
    // console.log(error);
  }

  // TODO: Add code to handle receipts that contain no transactions.
  return {};
}

// This function is the entry point for analyzing the receipt.
// It fetches the latest receipt data from the /verifyReceipt endpoint.
// It fails over to the sandbox environment if the receipt is from the
// sandbox environment. Add failover logic to support outages and
// invalid receipts data.
async function fetchLatestReceipt(receipt) {
  const secret = process.env.SHARED_SECRET;

  const options = {
    url: prodEndpoint,
    method: 'POST',
    headers: {
      Accept: 'application/json', 'Accept-Charset': 'utf-8',
    },
    json: {
      'receipt-data': receipt, password: secret,
    },
  };

  try {
    const body = await got.post(options).json();

    if (body.status === appReceiptStatus.SUCCESS) {
      return body;
    } if (body.status === appReceiptStatus.INCORRECT_SECRET) {
      // If the shared secret is invalid, determine how you want to failover.
      throw new Error('Invalid shared secret used to validate the data');
    } else if (body.status === appReceiptStatus.USE_TEST_ENV) {
      // If the receipt is a sandbox receipt, use the sandbox endpoint.
      const sandboxBody = await fetchLatestSandboxReceipt(receipt);
      return sandboxBody;
    } else {
      // TODO: Add code to handle failure conditions
      // Depending on the error and the origin of the request,
      // determine whether it's necessary to provide an entitlementCode status.
      // For example, if the entitlementCode attempt is made during a client
      // launch, it may be ideal to fail-over to persisted data, to manually
      // validate, or to retry.
    }
  } catch (error) {
    // console.log(error);
  }

  return {};
}

module.exports = {
  processReceiptJSON, fetchLatestReceipt,
};
