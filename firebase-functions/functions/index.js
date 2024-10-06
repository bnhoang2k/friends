/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// const {onRequest} = require("firebase-functions/v2/https");
// const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {SecretManagerServiceClient} = require("@google-cloud/secret-manager");

// Initialize Firebase Admin SDK
admin.initializeApp();

// Initialize secret manager
const secretClient = new SecretManagerServiceClient();

/**
 * This function gets the api key.
 *
 * @param {string} secretName - The name of the secret to get.
 * @return {string} return the api key
 */
async function getSecret(secretName) {
  try {
    const [accessResponse] = await secretClient.accessSecretVersion({
      name: `projects/friends-f19a5/secrets/${secretName}/versions/latest`,
    });
    return accessResponse.payload.data.toString("utf8");
  } catch (error) {
    console.error("Error retrieving secret: ", error);
    throw new functions.https.HttpsError("internal 1",
        "Error retrieving secret");
  }
}

exports.getTypesenseAPIKey = functions.https.onCall(async (data, context) => {
  // Optionally check if the user is authenticated
//   console.log("context: ", context);
//   if (!context.auth) {
//     throw new functions.https.HttpsError("unauthenticated",
//         "The function must be called while authenticated.");
//   }
  try {
    const typesenseAPIKey = await getSecret("TYPESENSE_USER_SEARCH_API_KEY");
    return {apiKey: typesenseAPIKey};
  } catch (error) {
    throw new functions.https.HttpsError("internal 2",
        "Failed to retrieve the API key");
  }
});
