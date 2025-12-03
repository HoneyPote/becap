import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import Stripe from "stripe";

admin.initializeApp();

const db = admin.firestore();
const region = "europe-west1";
const stripeSecret = functions.config().stripe?.secret_key as string | undefined;
const webhookSecret = functions.config().stripe?.webhook_secret as string | undefined;
const successUrl = functions.config().stripe?.success_url as string | undefined; // TODO: set to your app/link
const cancelUrl = functions.config().stripe?.cancel_url as string | undefined; // TODO: set to your app/link

const stripe = stripeSecret
  ? new Stripe(stripeSecret, { apiVersion: "2024-06-20" })
  : null;

interface ChallengePayload {
  challengeId: string;
  userId: string;
  method?: string;
}

const COLLECTION_CHALLENGES = "challenges";
const COLLECTION_ENROLLMENTS = "enrollments";

type PaymentStatus = "free" | "pending" | "paid" | "failed";

async function upsertEnrollment(params: {
  challengeId: string;
  userId: string;
  paymentStatus: PaymentStatus;
  provider?: string;
  paymentIntentId?: string;
  amountCents?: number;
  currency?: string;
}) {
  const ref = db
    .collection(COLLECTION_CHALLENGES)
    .doc(params.challengeId)
    .collection(COLLECTION_ENROLLMENTS)
    .doc(params.userId);

  const now = admin.firestore.FieldValue.serverTimestamp();

  await ref.set(
    {
      userId: params.userId,
      challengeId: params.challengeId,
      paymentStatus: params.paymentStatus,
      paymentProvider: params.provider,
      paymentIntentId: params.paymentIntentId,
      amountCents: params.amountCents,
      currency: params.currency,
      createdAt: now,
      lastUpdatedAt: now,
    },
    { merge: true },
  );
}

export const createStripePaymentIntentForChallenge = functions
  .region(region)
  .https.onCall(async (data: ChallengePayload, context) => {
    if (!stripe) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Stripe n’est pas configuré. Ajoutez stripe.secret_key dans les configs Functions.",
      );
    }

    const { challengeId, userId } = data;
    if (!challengeId || !userId) {
      throw new functions.https.HttpsError("invalid-argument", "challengeId et userId sont requis.");
    }

    const snap = await db.collection(COLLECTION_CHALLENGES).doc(challengeId).get();
    if (!snap.exists) {
      throw new functions.https.HttpsError("not-found", "Défi introuvable");
    }

    const challenge = snap.data() as any;
    if (!challenge.isPremium || !challenge.price) {
      throw new functions.https.HttpsError("failed-precondition", "Ce défi n’est pas payant.");
    }

    const amountCents = Math.round((challenge.price as number) * 100);
    const currency = (challenge.currency as string) ?? "eur";

    const paymentIntent = await stripe.paymentIntents.create({
      amount: amountCents,
      currency,
      metadata: {
        challengeId,
        userId,
      },
      automatic_payment_methods: { enabled: true },
    });

    await upsertEnrollment({
      challengeId,
      userId,
      paymentStatus: "pending",
      provider: "stripe",
      paymentIntentId: paymentIntent.id,
      amountCents,
      currency,
    });

    // Build a Checkout Session for browser-based card/Apple Pay (simpler for MVP)
    const session = await stripe.checkout.sessions.create({
      mode: "payment",
      payment_intent_data: {
        metadata: { challengeId, userId },
      },
      metadata: { challengeId, userId },
      line_items: [
        {
          quantity: 1,
          price_data: {
            currency,
            unit_amount: amountCents,
            product_data: {
              name: challenge.title || "Défi premium",
            },
          },
        },
      ],
      success_url: successUrl || "https://example.com/success", // TODO: replace with your app link
      cancel_url: cancelUrl || "https://example.com/cancel",
    });

    return {
      clientSecret: paymentIntent.client_secret,
      checkoutUrl: session.url,
    };
  });

export const stripeWebhook = functions.region(region).https.onRequest(async (req, res) => {
  if (!stripe || !webhookSecret) {
    res.status(500).send("Stripe non configuré");
    return;
  }

  const sig = req.headers["stripe-signature"] as string;

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, webhookSecret);
  } catch (err: any) {
    console.error("❌ Signature Stripe invalide", err.message);
    res.status(400).send(`Webhook Error: ${err.message}`);
    return;
  }

  if (event.type === "payment_intent.succeeded") {
    const intent = event.data.object as Stripe.PaymentIntent;
    const challengeId = intent.metadata.challengeId;
    const userId = intent.metadata.userId;

    if (challengeId && userId) {
      await upsertEnrollment({
        challengeId,
        userId,
        paymentStatus: "paid",
        provider: "stripe",
        paymentIntentId: intent.id,
        amountCents: intent.amount_received,
        currency: intent.currency,
      });
    }
  }

  if (event.type === "payment_intent.payment_failed") {
    const intent = event.data.object as Stripe.PaymentIntent;
    const challengeId = intent.metadata.challengeId;
    const userId = intent.metadata.userId;

    if (challengeId && userId) {
      await upsertEnrollment({
        challengeId,
        userId,
        paymentStatus: "failed",
        provider: "stripe",
        paymentIntentId: intent.id,
        amountCents: intent.amount,
        currency: intent.currency,
      });
    }
  }

  res.json({ received: true });
});
