const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const stripePackage = require("stripe");

/**
 * Initialize Stripe with the secret key from environment variables.
 * The secret key must never be exposed to the client.
 */
const stripeSecretKey = process.env.STRIPE_SECRET_KEY;
const stripePublishableKey = process.env.STRIPE_PUBLISHABLE_KEY;

if (!stripeSecretKey) {
  logger.error("Missing STRIPE_SECRET_KEY environment variable");
}

const stripe = stripeSecretKey ? stripePackage(stripeSecretKey) : null;

const DEFAULT_CURRENCY = "eur";
const DEFAULT_AMOUNT = 499; // Amount in the smallest currency unit (e.g. cents for EUR).

/**
 * Retrieve an existing Stripe customer for the Firebase user or create one if none exists.
 * The Firebase UID is stored in customer metadata for lookup.
 *
 * @param {string} userId Firebase Auth user UID
 * @returns {Promise<string>} The Stripe customer ID
 */
async function createOrRetrieveCustomer(userId) {
  if (!stripe) {
    throw new Error("Stripe is not initialized");
  }

  // Search for an existing customer tagged with this Firebase user id.
  const existing = await stripe.customers.search({
    query: `metadata['firebaseUserId']:'${userId}'`,
    limit: 1,
  });

  if (existing.data.length > 0) {
    return existing.data[0].id;
  }

  const customer = await stripe.customers.create({
    metadata: {
      firebaseUserId: userId,
    },
  });

  return customer.id;
}

/**
 * HTTPS endpoint for creating a PaymentSheet configuration.
 *
 * Expected POST body:
 * {
 *   "userId": "<Firebase UID>",
 *   "itemId": "<challenge or price identifier>"
 * }
 */
exports.createPaymentSheet = onRequest({ cors: true }, async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).json({ error: "Method Not Allowed" });
    return;
  }

  if (!stripe || !stripePublishableKey) {
    res.status(500).json({ error: "Stripe is not configured" });
    return;
  }

  const { userId, itemId } = req.body || {};

  if (!userId) {
    res.status(400).json({ error: "Missing required field 'userId'" });
    return;
  }

  try {
    const customerId = await createOrRetrieveCustomer(userId);

    // Create an ephemeral key for the customer so the client can access it via PaymentSheet.
    const ephemeralKey = await stripe.ephemeralKeys.create(
      { customer: customerId },
      { apiVersion: "2023-10-16" }
    );

    // For now we use a fixed amount for premium challenge unlocks.
    const paymentIntent = await stripe.paymentIntents.create({
      amount: DEFAULT_AMOUNT,
      currency: DEFAULT_CURRENCY,
      customer: customerId,
      metadata: {
        firebaseUserId: userId,
        itemId: itemId || "premium_challenge",
      },
      automatic_payment_methods: {
        enabled: true,
      },
    });

    res.status(200).json({
      paymentIntentClientSecret: paymentIntent.client_secret,
      ephemeralKeySecret: ephemeralKey.secret,
      customerId,
      publishableKey: stripePublishableKey,
    });
  } catch (error) {
    logger.error("Error creating PaymentSheet configuration", error);
    const status = error?.statusCode || 500;
    res.status(status).json({
      error: error?.message || "An unexpected error occurred.",
    });
  }
});
