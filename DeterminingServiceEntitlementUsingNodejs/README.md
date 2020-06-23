# Determining Service Entitlement Using Node.js

Determine a customer's entitlement to your service, offers, and messaging by analyzing a validated receipt and the state of their subscription.

## Overview

- Note: This sample code project is associated with WWDC 2020 session [10671: Architecting for Subscriptions](https://developer.apple.com/wwdc20/10671/).

When your app provides a subscription service, you receive data in the form of in-app receipts and App Store server notifications that tell you a subscription’s state. After interpreting this data, your app knows whether to open or restrict the user's access to service, products, offers, and messages.

This server-side sample code analyses a receipt to help your app determine entitlement. It systematically considers all potential subscription states that affect service entitlement, such as offers periods and billing states. The output from this sample’s REST API endpoints is a response that makes it clear whether that app should enable service or take other steps to retain or communicate with customers. You can extend this engine code and customize the response based on your own business logic.
The sample code contains two endpoints:
* URL: `localhost:3000/simulate` — Use `/simulate` for testing using real or artificial receipts. This endpoint requires no special configuration.
* URL: `localhost:3000/entitle` — Use `/entitle` with real base-64 encoded receipts. This endpoint requires additional configuration.

## Configure the Sample Code Project

Follow these steps to run the sample code project on your computer:

1. Install Node.js version 10.15.3.
2. Open the Terminal app (`/Applications/Utilities`).
3. Navigate to the sample code `/Sample` directory.
4. In Terminal, enter `npm install` and press Return; make sure it completes successfully
5. In Terminal, enter `npm start` and press Return to start the server. The server runs in your Terminal window. To stop the serve, press Control-C while in Terminal.
6. In Terminal, choose Shell > New Windows > New Window with Profile to open a second Teminal window that you'll use to send the requests.

## Send a Request Using Sample Receipt Data

The requests to the service entitlement engine take JSON data from a receipt. The data must be in the same JSON format that you receive by calling the `/verifyReceipt` endpoint when you pass it a valid receipt. The example file `flatJSONExample` in the `Source/Example` directory contains sample receipt data in the correct format for the requests. 

To run the request, switch to the second Terminal window and type the following `curl` command. Replace the `<FLAT JSON DATA>` with the `flatJSONExample`.

```
    curl -XPOST -H "Content-type: application/json" -d <FLAT JSON DATA > 'localhost:3000/simulate'
```    

If the mocked JSON receipt data is properly formed, the response contains the analyzed data the entitlement engine produced based on the receipt data.

If you have real receipt data, replace the `<FLAT JSON DATA>` in the command with your receipt data.


## Receive the Sample Response

The response contains the result of the engine's analysis of the receipt data. Use it to determine whether a subscriber is entitled to service, offers, or other messaging. The response object contains an array of subscription objects organized by product ID, each containing fields that provide insights for that subscription.

This example response shows a customer who was previously subscribed and then resubscribed again, with an active subscription with auto-renew still enabled. 

```
{
    "subscriptions": [
        {
            "product_id": "com.example.monthly",
            "entitlementCode": 5,
            "expiration": 1599391591000,
            "totalRenewals": 7,
            "groupID": "13472270",
            "originalTransactions": [
                {
                    "originalTX": "190000625698817",
                    "start": 1564455960000,
                    "expiration": 1599391591000,
                    "renewals": 7
                }
            ],
            "trialConsumed": true
        }
    ],
    "trialConsumedForGroup": [
        "13472270"
    ]
}
```

In this case, the hypothetical developer decided to issue an offer for a yearly subscription to the customer because they are in state `5` with `7` total renewals.
