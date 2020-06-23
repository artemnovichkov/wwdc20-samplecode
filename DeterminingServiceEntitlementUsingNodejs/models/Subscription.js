/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Constants and helper functions for structuring the subscription response.
*/

/*
See LICENSE folder for this sample’s licensing information.

 Abstract:
Constants and helper functions for structuring the subscription response.
*/


// State definitions for subscription products.
// Customize and modify these definitions to fit your business and product needs.
const subscriptionState = Object.freeze({
  // The subscription is active and auto-renew is on.
  ACTIVE_AUTO_REN_ON: 5,
  // The subscription is active and auto-renew is off.
  ACTIVE_AUTO_REN_OFF: 4,
  // The subscription is a non-renewing subscription.
  NON_REN_SUB: 3,
  // The subscription is an off-platform subscription.
  OFF_PLATFORM_SUB: 2,
  // The subscription expired, but is in grace period.
  EXPIRED_IN_GRACE: 1,
  // Not currently used
  // The receipt is out of date or there is another purchase issue.
  MISSING_PURCH_INFO: 0,
  // The receipt is expired but the subscription is still in a billing-retry state.
  // If grace period is enabled, this state excludes subscriptions in grace period.
  EXPIRED_IN_RETRY: -1,
  // The receipt is fully expired due to a billing issue.
  EXPIRED_FROM_BILLING: -2,
  // The customer did not accept the price increase.
  FAIL_TO_ACCEPT_INCREASE: -3,
  // The product is no longer available.
  PROD_NOT_AVAILABLE: -4,
  // The customer intentionally cancelled the subscription.
  EXP_VOLUNTARILY: -5,
  // The system canceled the subscription because the customer upgraded.
  UPGRADED: -6,
  // The customer received a refund due to a perceived issue with the app.
  ISSUE_REFUND: -7,
  // The customer received a refund for the subscription.
  OTHER_REFUND: -8,
});

// Substate definitions for subscription products.
// Customize and modify these definitions to fit your business and product needs.
const subscriptionSubState = Object.freeze({
  // Subscription product is in the standard state.
  STANDARD_SUB: 0.0,
  // Subscription is in the free-trial offer state.
  FREE_TRIAL: 0.1,
  // Subscription is in the introductory offer state.
  INTRODUCTORY: 0.2,
  // Subscription is in a subscription offer state.
  SUB_OFFER: 0.3,
});

// Create a subscription object based on a transaction.
// Subscription transactions are grouped by their product IDs.
// Optionally, extend this function by returning custom fields in the response,
// for example, like hours watched.
function Subscription(transaction) {
  this.product_id = transaction.product_id;

  // If the transaction doesn't contain an expiration, the subscription is non-renewing.
  if (transaction.expires_date_ms) {
    this.entitlementCode = subscriptionState.EXP_VOLUNTARILY;
    this.expiration = Number(transaction.expires_date_ms);
  } else {
    this.entitlementCode = subscriptionState.NON_REN_SUB;
  }

  // Keep track of the number of renewals.
  this.totalRenewals = 0;
  // Keep track of the group ID of a subscription.
  this.groupID = transaction.subscription_group_identifier;

  // An array for original transactions, used incase a single product ID has multiple
  // original transactions.
  this.originalTransactions = [];

  // Subscription helper functions to interchange the state without changing the substate.
  this.setMainState = function setMainState(newInt) {
    const sign = newInt && newInt / Math.abs(newInt);
    const OldCode = Math.abs(this.entitlementCode);
    const intPart = Math.trunc(OldCode);
    const absNewInt = Math.abs(newInt);
    const val = (OldCode - intPart) + absNewInt;
    // Prevent round-off errors with any further calculations.
    this.entitlementCode = val.toFixed(2) * sign;
  };

  // Subscription helper functions to interchange the substate without changing the state.
  this.setSubState = function setSubState(newDecimal) {
    const current = this.entitlementCode;
    const absOld = Math.abs(current);
    const OldInt = Math.floor(absOld);
    const sign = current && current / Math.abs(current);
    this.entitlementCode = (OldInt + newDecimal).toFixed(2) * sign;
  };
}

// Export these objects so other classes can use them.
module.exports = {
  Subscription, subscriptionState, subscriptionSubState,
};
