const admin = require('firebase-admin');
const cors = require('cors');
const express = require('express');
const { onRequest } = require('firebase-functions/v2/https');

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const app = express();
const paymentsCollection = db.collection('payment_attempts');
const publicCors = cors({ origin: true });

app.use(publicCors);
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.post('/sslcommerz/initiate', requireAuth, async (req, res) => {
  try {
    const draft = normalizeDraft(req.body?.draft);
    validateDraft(draft, req.auth.uid);

    const gatewayConfig = getSslCommerzConfig();
    const attemptRef = paymentsCollection.doc();
    const attemptId = attemptRef.id;
    const tranId = buildTransactionId(attemptId);
    const callbackBase = `${getPublicFunctionsBaseUrl()}/payments/sslcommerz`;

    await attemptRef.set({
      userId: draft.userId,
      customerEmail: draft.customerEmail,
      status: 'initiated',
      paymentStatus: 'initiated',
      paymentMethod: 'online',
      gateway: 'sslcommerz',
      amount: draft.total,
      currency: draft.currency,
      tranId,
      checkoutSnapshot: draft,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const payload = new URLSearchParams({
      store_id: gatewayConfig.storeId,
      store_passwd: gatewayConfig.storePassword,
      total_amount: draft.total.toFixed(2),
      currency: draft.currency,
      tran_id: tranId,
      success_url: `${callbackBase}/success?attemptId=${attemptId}`,
      fail_url: `${callbackBase}/fail?attemptId=${attemptId}`,
      cancel_url: `${callbackBase}/cancel?attemptId=${attemptId}`,
      ipn_url: `${callbackBase}/ipn?attemptId=${attemptId}`,
      cus_name: draft.deliveryAddress.fullName,
      cus_email: draft.customerEmail,
      cus_add1: draft.deliveryAddress.addressLine1,
      cus_add2: draft.deliveryAddress.addressLine2,
      cus_city: draft.deliveryAddress.city,
      cus_state: draft.deliveryAddress.city,
      cus_postcode: draft.deliveryAddress.postalCode,
      cus_country: draft.deliveryAddress.country,
      cus_phone: draft.deliveryAddress.phone,
      ship_name: draft.deliveryAddress.fullName,
      ship_add1: draft.deliveryAddress.addressLine1,
      ship_add2: draft.deliveryAddress.addressLine2,
      ship_city: draft.deliveryAddress.city,
      ship_state: draft.deliveryAddress.city,
      ship_postcode: draft.deliveryAddress.postalCode,
      ship_country: draft.deliveryAddress.country,
      shipping_method: 'NO',
      product_name: buildProductName(draft.items),
      product_category: 'Ecommerce',
      product_profile: 'general',
      value_a: attemptId,
      value_b: draft.userId,
      value_c: draft.couponCode || '',
      value_d: draft.deliveryDate,
    });

    const gatewayResponse = await fetchJson(gatewayConfig.initiateUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: payload,
    });

    if (!gatewayResponse.GatewayPageURL) {
      await attemptRef.set(
        {
          status: 'invalid',
          paymentStatus: 'invalid',
          message: gatewayResponse.failedreason || 'Gateway session was not created.',
          gatewayInitResponse: sanitizeGatewayResponse(gatewayResponse),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      return res.status(502).json({
        message: gatewayResponse.failedreason || 'Unable to create SSLCOMMERZ session.',
      });
    }

    await attemptRef.set(
      {
        status: 'pending',
        paymentStatus: 'pending',
        message: 'Redirect to SSLCOMMERZ to complete payment.',
        gatewayPageUrl: gatewayResponse.GatewayPageURL,
        sessionKey: gatewayResponse.sessionkey || '',
        gatewayInitResponse: sanitizeGatewayResponse(gatewayResponse),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    return res.status(200).json({
      attemptId,
      gateway: 'sslcommerz',
      gatewayUrl: gatewayResponse.GatewayPageURL,
      transactionId: tranId,
      status: 'pending',
      message: 'Redirect to SSLCOMMERZ to complete payment.',
    });
  } catch (error) {
    return handleHttpError(res, error);
  }
});

app.get('/status/:attemptId', requireAuth, async (req, res) => {
  try {
    const attemptSnap = await paymentsCollection.doc(req.params.attemptId).get();
    if (!attemptSnap.exists) {
      return res.status(404).json({ message: 'Payment attempt not found.' });
    }

    const attempt = attemptSnap.data();
    if (attempt.userId !== req.auth.uid) {
      return res.status(403).json({ message: 'You cannot access this payment attempt.' });
    }

    return res.status(200).json(paymentStatusPayload(attemptSnap.id, attempt));
  } catch (error) {
    return handleHttpError(res, error);
  }
});

app.all('/sslcommerz/success', async (req, res) => {
  try {
    const context = await resolveAttemptContext(req);
    if (!context) {
      return res.status(404).send(renderStatusPage('Payment attempt not found', 'The payment attempt could not be located.'));
    }

    const result = await finalizeSuccessfulPayment(context, req);
    return res.status(result.httpStatus).send(renderStatusPage(result.title, result.message));
  } catch (error) {
    return res.status(500).send(renderStatusPage('Payment verification failed', error.message || 'Unexpected verification error.'));
  }
});

app.all('/sslcommerz/fail', async (req, res) => {
  try {
    const context = await resolveAttemptContext(req);
    if (!context) {
      return res.status(404).send(renderStatusPage('Payment failed', 'The payment attempt could not be located.'));
    }

    const result = await updateAttemptTerminalState(
      context,
      'failed',
      req,
      'Payment failed or was declined at SSLCOMMERZ.',
    );
    return res.status(200).send(renderStatusPage('Payment failed', result.message));
  } catch (error) {
    return res.status(500).send(renderStatusPage('Payment failed', error.message || 'Unexpected payment failure.'));
  }
});

app.all('/sslcommerz/cancel', async (req, res) => {
  try {
    const context = await resolveAttemptContext(req);
    if (!context) {
      return res.status(404).send(renderStatusPage('Payment cancelled', 'The payment attempt could not be located.'));
    }

    const result = await updateAttemptTerminalState(
      context,
      'cancelled',
      req,
      'Payment was cancelled before completion.',
    );
    return res.status(200).send(renderStatusPage('Payment cancelled', result.message));
  } catch (error) {
    return res.status(500).send(renderStatusPage('Payment cancelled', error.message || 'Unexpected cancellation.'));
  }
});

app.all('/sslcommerz/ipn', async (req, res) => {
  try {
    const context = await resolveAttemptContext(req);
    if (!context) {
      return res.status(404).json({ message: 'Payment attempt not found.' });
    }

    const valId = readCallbackValue(req, 'val_id');
    if (valId) {
      const result = await finalizeSuccessfulPayment(context, req);
      return res.status(result.httpStatus).json({
        status: result.status,
        message: result.message,
      });
    }

    const result = await updateAttemptTerminalState(
      context,
      'pending',
      req,
      'IPN received without a validation id.',
    );
    return res.status(200).json(result);
  } catch (error) {
    return handleHttpError(res, error);
  }
});

exports.payments = onRequest(
  {
    region: 'us-central1',
    cors: true,
    timeoutSeconds: 60,
  },
  app,
);

async function requireAuth(req, res, next) {
  try {
    const authorization = req.get('Authorization') || '';
    if (!authorization.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'Missing Firebase auth token.' });
    }

    const token = authorization.substring('Bearer '.length);
    req.auth = await admin.auth().verifyIdToken(token);
    return next();
  } catch (error) {
    return res.status(401).json({ message: 'Invalid Firebase auth token.' });
  }
}

function normalizeDraft(rawDraft) {
  const draft = rawDraft && typeof rawDraft === 'object' ? rawDraft : {};
  return {
    userId: String(draft.userId || '').trim(),
    customerEmail: String(draft.customerEmail || '').trim(),
    items: Array.isArray(draft.items) ? draft.items : [],
    deliveryAddress:
      draft.deliveryAddress && typeof draft.deliveryAddress === 'object'
        ? draft.deliveryAddress
        : {},
    notes: String(draft.notes || '').trim(),
    couponCode: String(draft.couponCode || '').trim(),
    deliveryDate: String(draft.deliveryDate || '').trim(),
    paymentMethod: String(draft.paymentMethod || 'online').trim(),
    paymentGateway: String(draft.paymentGateway || 'sslcommerz').trim(),
    subtotal: Number(draft.subtotal || 0),
    tax: Number(draft.tax || 0),
    deliveryCharge: Number(draft.deliveryCharge || 0),
    total: Number(draft.total || 0),
    currency: String(draft.currency || 'BDT').trim(),
  };
}

function validateDraft(draft, authUid) {
  if (!draft.userId || draft.userId !== authUid) {
    throw httpError(403, 'Authenticated user does not match the checkout payload.');
  }
  if (!draft.customerEmail) {
    throw httpError(400, 'Customer email is required for SSLCOMMERZ checkout.');
  }
  if (!draft.items.length) {
    throw httpError(400, 'Cart is empty.');
  }
  if (!draft.deliveryAddress.fullName || !draft.deliveryAddress.phone) {
    throw httpError(400, 'Customer name and phone are required.');
  }
  if (!draft.deliveryAddress.addressLine1 || !draft.deliveryAddress.city) {
    throw httpError(400, 'Delivery address is incomplete.');
  }
  if (!Number.isFinite(draft.total) || draft.total < 10) {
    throw httpError(400, 'Total amount must be at least 10 BDT.');
  }
}

function getSslCommerzConfig() {
  const isLive = String(process.env.SSLCOMMERZ_IS_LIVE || 'false').toLowerCase() === 'true';
  const storeId = process.env.SSLCOMMERZ_STORE_ID || 'testbox';
  const storePassword = process.env.SSLCOMMERZ_STORE_PASSWORD || 'qwerty';
  const host = isLive
    ? 'https://securepay.sslcommerz.com'
    : 'https://sandbox.sslcommerz.com';

  return {
    isLive,
    storeId,
    storePassword,
    initiateUrl: `${host}/gwprocess/v4/api.php`,
    validateUrl: `${host}/validator/api/validationserverAPI.php`,
  };
}

function getPublicFunctionsBaseUrl() {
  if (process.env.PUBLIC_FUNCTIONS_BASE_URL) {
    return process.env.PUBLIC_FUNCTIONS_BASE_URL.replace(/\/$/, '');
  }

  const projectId =
    process.env.GCLOUD_PROJECT ||
    process.env.FIREBASE_CONFIG_PROJECT_ID ||
    admin.app().options.projectId ||
    'wafi-ecommerce';
  return `https://us-central1-${projectId}.cloudfunctions.net`;
}

async function resolveAttemptContext(req) {
  const attemptId =
    readCallbackValue(req, 'attemptId') || readCallbackValue(req, 'value_a');
  if (attemptId) {
    const attemptSnap = await paymentsCollection.doc(attemptId).get();
    if (attemptSnap.exists) {
      return {
        attemptId: attemptSnap.id,
        ref: attemptSnap.ref,
        data: attemptSnap.data(),
      };
    }
  }

  const tranId = readCallbackValue(req, 'tran_id');
  if (!tranId) return null;

  const snapshot = await paymentsCollection
    .where('tranId', '==', tranId)
    .limit(1)
    .get();

  if (snapshot.empty) return null;
  const doc = snapshot.docs.first;
  return {
    attemptId: doc.id,
    ref: doc.ref,
    data: doc.data(),
  };
}

async function finalizeSuccessfulPayment(context, req) {
  if (context.data.orderId) {
    return {
      httpStatus: 200,
      status: 'paid',
      title: 'Payment already confirmed',
      message: 'This payment was already verified and the order is available in your account.',
    };
  }

  const valId = readCallbackValue(req, 'val_id');
  if (!valId) {
    await markAttemptInvalid(context, req, 'Validation ID was missing from the SSLCOMMERZ callback.');
    return {
      httpStatus: 400,
      status: 'invalid',
      title: 'Payment verification failed',
      message: 'SSLCOMMERZ did not provide a validation ID for this payment.',
    };
  }

  const validation = await validateTransaction(valId);
  const amountFromGateway = Number(validation.amount || 0);
  const isValidStatus = ['VALID', 'VALIDATED'].includes(
    String(validation.status || '').toUpperCase(),
  );
  const amountMatches =
    Math.abs(amountFromGateway - Number(context.data.amount || 0)) < 0.01;
  const tranMatches =
    String(validation.tran_id || '').trim() === String(context.data.tranId || '').trim();

  if (!isValidStatus || !amountMatches || !tranMatches) {
    await context.ref.set(
      {
        status: 'invalid',
        paymentStatus: 'invalid',
        message: 'SSLCOMMERZ validation failed for this transaction.',
        callbackPayload: extractCallbackPayload(req),
        validationResponse: summarizeValidation(validation),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    return {
      httpStatus: 400,
      status: 'invalid',
      title: 'Payment verification failed',
      message: 'Transaction validation did not match the expected amount or transaction ID.',
    };
  }

  try {
    await db.runTransaction(async (transaction) => {
      const latestSnap = await transaction.get(context.ref);
      const latest = latestSnap.data();

      if (!latest || latest.orderId) {
        return;
      }

      const reservedInventory = await reserveInventoryInTransaction(
        transaction,
        Array.isArray(latest.checkoutSnapshot?.items)
          ? latest.checkoutSnapshot.items
          : [],
      );
      const orderRef = db.collection('orders').doc(context.attemptId);
      const orderNumber = generateOrderNumber();

      transaction.set(
        orderRef,
        buildOrderDocument(
          context.attemptId,
          latest,
          validation,
          orderNumber,
          reservedInventory,
        ),
      );
      transaction.set(
        context.ref,
        {
          status: 'paid',
          paymentStatus: 'paid',
          message: 'Payment verified and order created.',
          orderId: orderNumber,
          orderDocumentId: context.attemptId,
          orderNumber,
          gatewayTransactionId: String(validation.tran_id || latest.tranId || ''),
          gatewayValidationId: String(validation.val_id || valId),
          bankTransactionId: String(validation.bank_tran_id || ''),
          callbackPayload: extractCallbackPayload(req),
          validationResponse: summarizeValidation(validation),
          paidAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    });

    return {
      httpStatus: 200,
      status: 'paid',
      title: 'Payment successful',
      message: 'Your payment was verified and the order has been placed successfully.',
    };
  } catch (error) {
    const message = error?.message || 'Stock was no longer available for one or more items.';
    await context.ref.set(
      {
        status: 'invalid',
        paymentStatus: 'invalid',
        message: `Payment captured but order creation was blocked: ${message}`,
        callbackPayload: extractCallbackPayload(req),
        validationResponse: summarizeValidation(validation),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    return {
      httpStatus: error?.statusCode || 409,
      status: 'invalid',
      title: 'Order could not be created',
      message,
    };
  }
}

async function updateAttemptTerminalState(context, nextStatus, req, message) {
  const currentStatus = String(context.data.status || '').toLowerCase();
  if (currentStatus === 'paid') {
    return {
      status: 'paid',
      message: 'This payment has already been verified successfully.',
    };
  }

  await context.ref.set(
    {
      status: nextStatus,
      paymentStatus: nextStatus,
      message,
      callbackPayload: extractCallbackPayload(req),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return {
    status: nextStatus,
    message,
  };
}

async function markAttemptInvalid(context, req, message) {
  await context.ref.set(
    {
      status: 'invalid',
      paymentStatus: 'invalid',
      message,
      callbackPayload: extractCallbackPayload(req),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

async function validateTransaction(valId) {
  const config = getSslCommerzConfig();
  const query = new URLSearchParams({
    val_id: valId,
    store_id: config.storeId,
    store_passwd: config.storePassword,
    v: '1',
    format: 'json',
  });

  return fetchJson(`${config.validateUrl}?${query.toString()}`);
}

async function fetchJson(url, options = undefined) {
  const response = await fetch(url, options);
  const text = await response.text();
  let json;

  try {
    json = text ? JSON.parse(text) : {};
  } catch (error) {
    throw httpError(502, 'Gateway returned a non-JSON response.');
  }

  if (!response.ok) {
    throw httpError(
      response.status,
      json.failedreason || json.message || 'Gateway request failed.',
    );
  }

  return json;
}

function buildOrderDocument(
  attemptId,
  attempt,
  validation,
  orderNumber,
  stockBeforeByProduct = {},
) {
  const snapshot = attempt.checkoutSnapshot || {};
  const deliveryDate = parseIsoDate(snapshot.deliveryDate);
  const gatewayTransactionId = String(validation.tran_id || attempt.tranId || '');
  const gatewayValidationId = String(validation.val_id || '');

  return {
    orderId: orderNumber,
    userId: attempt.userId,
    customerEmail: attempt.customerEmail || snapshot.customerEmail || '',
    items: attachInventorySnapshots(
      Array.isArray(snapshot.items) ? snapshot.items : [],
      stockBeforeByProduct,
    ),
    status: 'pending',
    inventoryReserved: true,
    inventoryRestocked: false,
    inventoryReservedAt: admin.firestore.FieldValue.serverTimestamp(),
    inventoryRestockedAt: null,
    paymentMethod: 'online',
    paymentStatus: 'paid',
    paymentGateway: 'sslcommerz',
    gatewayTransactionId,
    gatewayValidationId,
    paymentMetadata: {
      gateway: 'sslcommerz',
      paymentAttemptId: attemptId,
      gatewayTransactionId,
      gatewayValidationId,
    },
    deliveryAddress:
      snapshot.deliveryAddress && typeof snapshot.deliveryAddress === 'object'
        ? snapshot.deliveryAddress
        : {},
    subtotal: Number(snapshot.subtotal || 0),
    tax: Number(snapshot.tax || 0),
    deliveryCharge: Number(snapshot.deliveryCharge || 0),
    total: Number(snapshot.total || 0),
    notes: String(snapshot.notes || '').trim(),
    couponCode: String(snapshot.couponCode || '').trim(),
    deliveryDate: deliveryDate
      ? admin.firestore.Timestamp.fromDate(deliveryDate)
      : null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    confirmedAt: null,
    shippedAt: null,
    deliveredAt: null,
  };
}

async function reserveInventoryInTransaction(transaction, items) {
  const quantityByProduct = aggregateItemQuantities(items);
  const entries = Object.entries(quantityByProduct);

  if (!entries.length) {
    throw httpError(400, 'Cart is empty.');
  }

  const stockBeforeByProduct = {};
  for (const [productId, quantity] of entries) {
    const productRef = db.collection('products').doc(productId);
    const productSnap = await transaction.get(productRef);

    if (!productSnap.exists) {
      throw httpError(409, 'Some items are no longer available.');
    }

    const product = productSnap.data() || {};
    const isActive = Boolean(product.isActive);
    const stock = Number(product.stock || 0);
    const name = String(product.name || 'This product').trim();

    if (!isActive) {
      throw httpError(409, `${name} is no longer available.`);
    }
    if (stock < quantity) {
      throw httpError(
        409,
        stock <= 0 ? `${name} is out of stock.` : `Only ${stock} unit(s) left for ${name}.`,
      );
    }

    stockBeforeByProduct[productId] = stock;
    transaction.update(productRef, {
      stock: stock - quantity,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  return stockBeforeByProduct;
}

function aggregateItemQuantities(items) {
  const quantityByProduct = {};

  for (const item of Array.isArray(items) ? items : []) {
    const productId = String(item?.productId || '').trim();
    const quantity = Number(item?.quantity || 0);
    if (!productId || quantity <= 0) continue;
    quantityByProduct[productId] = (quantityByProduct[productId] || 0) + quantity;
  }

  return quantityByProduct;
}

function attachInventorySnapshots(items, stockBeforeByProduct) {
  return (Array.isArray(items) ? items : []).map((item) => {
    const productId = String(item?.productId || '').trim();
    return {
      ...item,
      stockBefore:
        productId && Object.prototype.hasOwnProperty.call(stockBeforeByProduct, productId)
          ? stockBeforeByProduct[productId]
          : null,
    };
  });
}

function paymentStatusPayload(attemptId, attempt) {
  return {
    attemptId,
    gateway: 'sslcommerz',
    status: String(attempt.status || 'unknown'),
    paymentStatus: String(attempt.paymentStatus || attempt.status || 'unknown'),
    gatewayUrl: String(attempt.gatewayPageUrl || ''),
    transactionId: String(attempt.tranId || ''),
    orderId: String(attempt.orderId || ''),
    message: String(attempt.message || ''),
  };
}

function buildTransactionId(attemptId) {
  return `WAFIPAY-${attemptId.substring(0, 20).toUpperCase()}`;
}

function buildProductName(items) {
  if (!Array.isArray(items) || !items.length) {
    return 'Wafi Ecommerce Order';
  }

  const names = items
    .map((item) => String(item.productName || '').trim())
    .filter(Boolean);
  return names.slice(0, 3).join(', ').substring(0, 200) || 'Wafi Ecommerce Order';
}

function generateOrderNumber() {
  const now = new Date();
  const yyyy = now.getFullYear();
  const mm = String(now.getMonth() + 1).padStart(2, '0');
  const dd = String(now.getDate()).padStart(2, '0');
  const stamp = String(now.getTime()).slice(-6);
  return `WAFI-${yyyy}${mm}${dd}-${stamp}`;
}

function parseIsoDate(value) {
  if (!value) return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

function sanitizeGatewayResponse(response) {
  return {
    status: String(response.status || ''),
    apiConnect: String(response.APIConnect || ''),
    sessionkey: String(response.sessionkey || ''),
    failedreason: String(response.failedreason || ''),
  };
}

function summarizeValidation(validation) {
  return {
    status: String(validation.status || ''),
    tran_id: String(validation.tran_id || ''),
    val_id: String(validation.val_id || ''),
    amount: String(validation.amount || ''),
    card_type: String(validation.card_type || ''),
    bank_tran_id: String(validation.bank_tran_id || ''),
    risk_level: String(validation.risk_level || ''),
    risk_title: String(validation.risk_title || ''),
  };
}

function extractCallbackPayload(req) {
  return {
    ...sanitizePayload(req.query),
    ...sanitizePayload(req.body),
  };
}

function sanitizePayload(payload) {
  if (!payload || typeof payload !== 'object') return {};

  return Object.fromEntries(
    Object.entries(payload).map(([key, value]) => [
      key,
      Array.isArray(value) ? value.join(',') : String(value ?? ''),
    ]),
  );
}

function readCallbackValue(req, key) {
  const queryValue = req.query?.[key];
  if (typeof queryValue === 'string' && queryValue.trim().length > 0) {
    return queryValue.trim();
  }

  const bodyValue = req.body?.[key];
  if (typeof bodyValue === 'string' && bodyValue.trim().length > 0) {
    return bodyValue.trim();
  }

  return '';
}

function renderStatusPage(title, message) {
  return `<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>${escapeHtml(title)}</title>
    <style>
      body {
        margin: 0;
        font-family: Arial, sans-serif;
        background: #f5f6f8;
        color: #202733;
        display: flex;
        align-items: center;
        justify-content: center;
        min-height: 100vh;
      }
      .card {
        max-width: 420px;
        margin: 24px;
        padding: 32px 28px;
        border-radius: 18px;
        background: #ffffff;
        box-shadow: 0 18px 50px rgba(15, 23, 42, 0.10);
        text-align: center;
      }
      h1 {
        margin: 0 0 12px;
        font-size: 24px;
      }
      p {
        margin: 0;
        line-height: 1.6;
      }
    </style>
  </head>
  <body>
    <div class="card">
      <h1>${escapeHtml(title)}</h1>
      <p>${escapeHtml(message)}</p>
    </div>
  </body>
</html>`;
}

function escapeHtml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}

function httpError(status, message) {
  const error = new Error(message);
  error.statusCode = status;
  return error;
}

function handleHttpError(res, error) {
  const statusCode = error.statusCode || 500;
  return res.status(statusCode).json({
    message: error.message || 'Unexpected server error.',
  });
}
