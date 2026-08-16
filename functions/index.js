const {onRequest} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const logger = require("firebase-functions/logger");

const openAIAPIKey = defineSecret("OPENAI_API_KEY");
const OPENAI_RESPONSES_URL = "https://api.openai.com/v1/responses";
const OPENAI_TIMEOUT_MS = 75_000;

exports.scoreChallengePhoto = onRequest(
    {
      region: "us-central1",
      timeoutSeconds: 120,
      memory: "512MiB",
      secrets: [openAIAPIKey],
      cors: false,
    },
    async (request, response) => {
      if (request.method !== "POST") {
        response.set("Allow", "POST").status(405).json({
          error: {message: "Méthode non autorisée."},
        });
        return;
      }

      if (!request.is("application/json") || !isValidResponsesPayload(request.body)) {
        response.status(400).json({
          error: {message: "Requête de scoring invalide."},
        });
        return;
      }

      try {
        const openAIResponse = await fetch(OPENAI_RESPONSES_URL, {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${openAIAPIKey.value()}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify(request.body),
          signal: AbortSignal.timeout(OPENAI_TIMEOUT_MS),
        });
        const body = await openAIResponse.text();
        response.status(openAIResponse.status);
        response.type(openAIResponse.headers.get("content-type") || "application/json");
        response.send(body);
      } catch (error) {
        const timedOut = error?.name === "TimeoutError" || error?.name === "AbortError";
        logger.error("OpenAI scoring request failed", {
          timedOut,
          name: error?.name,
          message: error?.message,
        });
        response.status(timedOut ? 504 : 502).json({
          error: {
            message: timedOut ?
              "Le service de scoring a pris trop de temps à répondre." :
              "Le service de scoring est temporairement indisponible.",
          },
        });
      }
    },
);

function isValidResponsesPayload(body) {
  if (!body || typeof body !== "object" || Array.isArray(body)) return false;
  if (body.model !== "gpt-4.1-mini" || !Array.isArray(body.input)) return false;

  return body.input.some((item) =>
    Array.isArray(item?.content) && item.content.some((content) =>
      content?.type === "input_image" &&
      typeof content.image_url === "string" &&
      content.image_url.startsWith("data:image/jpeg;base64,"),
    ),
  );
}
