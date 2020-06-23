/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The endpoints that the entitlement engine exposes.
*/


/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The endpoints that the entitlement engine exposes.
*/

const express = require('express');

const router = express.Router();

// The functions to which we pass the request data for receipt processing.
const { processReceiptJSON, fetchLatestReceipt } = require('../services/receiptProcessor');

// Endpoint: /simulate
// Analyze a mocked receipt.
// Send a mocked JSON receipt response to this engine endpoint to test receipt scenarios.
// Send the receipt in plain JSON format, same format received from App Store's /verifyReceipt
// endpoint.
router.post('/simulate', (req, res) => {
  const result = processReceiptJSON(req.body);

  // Send the response.
  res.setHeader('Content-Type', 'application/json');
  res.json(result);
});

// Endpoint: /entitle
// Analyze receipt data that the endpoint fetches from /verifyReceipt.
router.post('/entitle',
  async (req, res, next) => {
    // The actual responsibility of the route layer.
    const { receipt } = req.body;

    // Get the latest receipt data from Apple's /verifyReceipt endpoint.
    const latestReceiptData = await fetchLatestReceipt(receipt).catch((error) => {
      // TODO: Build error handling and failover support
      // console.log(error);
    });

    // Initialize an empty response.
    let result = {};
    if (latestReceiptData) {
      result = processReceiptJSON(latestReceiptData);
    }

    // Return a response to client.
    return res.json(result);
  });

module.exports = router;
