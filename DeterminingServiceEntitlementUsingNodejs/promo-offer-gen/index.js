/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This generates promotional offer signatures
*/


// Offer Signature Dependencies
// These can be removed if not using signature generation
const ECKey = require('ec-key');

const uuidv4 = require('uuid/v4');

// Signature generation code previously published
function getKeyID() {
  /*
          If you have multiple key IDs and apps, implement logic here to choose a key ID based on criteria such as which
          app is requesting a signature. You can also use this function to swap out key IDs if you determine that one of
          your keys has been compromised.

          This key ID was injected into an environment variable in the 'start-server' script using a value you provided.
      */
  return process.env.SUBSCRIPTION_OFFERS_KEY_ID;
}

function getKeyStringForID(keyID) {
  if (keyID === process.env.SUBSCRIPTION_OFFERS_KEY_ID) {
    /*
                This key was injected into an environment variable using the value you provided
                in the 'start-server' script.
            */
    return process.env.SUBSCRIPTION_OFFERS_PRIVATE_KEY;
  }
  throw 'Key ID not recognized';
}

function generateOffer(appBundleID, offerProductID, subscriptionOfferID, applicationUsername) {
  /*
          You can add code here to filter the requests or determine if the customer is eligible for this offer,
          based on App Store rules and your own business logic.

          For example, you may want to enable or disable certain bundle IDs, or perform different behavior or
          logging depending on the given bundle ID.
      */

  /*
   Decide beforehand which product the offer will be made for, not always the current product but
   SHOULD BE IN THE SAME GROUP
  */

  /*
          The nonce is a lowercase random UUID string that ensures the payload is unique.
          The App Store checks the nonce when your app starts a transaction with SKPaymentQueue,
          to prevent replay attacks.
      */
  const nonce = uuidv4();

  /*
          Get the current time and create a UNIX epoch timestamp in milliseconds.
          The timestamp ensures the signature was generated recently. The App Store also uses this
          information help prevent replay attacks.
      */
  const currentDate = new Date();
  const timestamp = currentDate.getTime();

  /*
          The key ID is for the key generated in App Store Connect that is associated with your account.
          For information on how to generate a key ID and key, see:
          "Generate keys for auto-renewable subscriptions" https://help.apple.com/app-store-connect/#/dev689c93225
      */
  const keyID = getKeyID();

  /*
          Combine the parameters into the payload string to be signed. These are the same parameters you provide
          in SKPaymentDiscount.
      */
  const payload = `${appBundleID}\u2063${keyID}\u2063${offerProductID}\u2063${subscriptionOfferID}\u2063${applicationUsername}\u2063${nonce}\u2063${timestamp}`;

  // Get the PEM-formatted private key string associated with the Key ID.
  const keyString = getKeyStringForID(keyID);

  // Create an Elliptic Curve Digital Signature Algorithm (ECDSA) object using the private key.
  const key = new ECKey(keyString, 'pem');

  // Set up the cryptographic format used to sign the key with the SHA-256 hashing algorithm.
  const cryptoSign = key.createSign('SHA256');

  // Add the payload string to sign.
  cryptoSign.update(payload);

  /*
          The Node.js crypto library creates a DER-formatted binary value signature,
          and then base-64 encodes it to create the string that you will use in StoreKit.
      */
  const signature = cryptoSign.sign('base64');

  /*
          Check that the signature passes verification by using the ec-key library.
          The verification process is similar to creating the signature, except it uses 'createVerify'
          instead of 'createSign', and after updating it with the payload, it uses `verify` to pass in
          the signature and encoding, instead of `sign` to get the signature.

          This step is not required, but it's useful to check when implementing your signature code.
          This helps debug issues with signing before sending transactions to Apple.
          If verification succeeds, the next recommended testing step is attempting a purchase
          in the Sandbox environment.
      */
  // Uncomment line to verify signature
  // const verificationResult = key.createVerify('SHA256').update(payload).verify(signature,
  // 'base64');

  // console.log(`Verification result: ${verificationResult}`);

  // Create Offer object to attach to the subscription
  const offer = {
    appBundleID, keyID, offerProductID, subscriptionOfferID, applicationUsername, nonce, timestamp, signature,
  };

  // Attach offer info to sub as an offer object for the client to use with StoreKit
  // sub.applicationUsername;
  // sub.offerID = offerID;
  // sub.offerProductID = offerProductID;
  // sub.keyID = keyID;
  // sub.timestamp = timestamp;
  // sub.signature = signature;
  return offer;
}

exports.generateOffer = generateOffer;
