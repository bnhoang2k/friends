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

// Initialize database
const db = admin.firestore();

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

exports.handleFriendRequests = functions.https.onCall(async (data, context) => {
  try {
    // Extract and log incoming data for debugging
    // console.log("Received data:", data);
    const {from_uid, to_uid, from_username, from_pp} = data.data;
    // console.log(
    //    "Parsed data:",
    //    "fromUserId:", fromUserId,
    //    "toUserId:", toUserId,
    //    "fromUsername:", fromUsername,
    //    "fromUserPP:", fromUserPP,
    // );

    // Create a new notification reference
    const notificationRef = db.collection("notifications").doc();
    const notification_id = notificationRef.id;

    const friendRequestNotification = {
      notification_id,
      from_uid,
      from_pp: from_pp,
      to_uid,
      type: "friendRequest",
      message: `${from_username} wants to be your friend`,
      status: "pending",
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Write data to Firestore in a transaction
    await db.runTransaction(async (transaction) => {
      const notificationSnapshot = await transaction.get(notificationRef);
      if (!notificationSnapshot.exists) {
        transaction.set(notificationRef, friendRequestNotification);
      } else {
        throw new Error("Friend request already exists.");
      }
    });

    return {notification_id: notification_id};
  } catch (error) {
    // Log the error for debugging
    console.error("Error handling friend request notification:", error.message);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

exports.unsendFriendRequest = functions.https.onCall(async (data, context) => {
  const {notification_id} = data.data;
  if (!notification_id) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "The notification ID is missing.",
    );
  }

  try {
    await db.runTransaction(async (transaction) => {
      const notificationRef = db.collection("notifications").doc(notification_id);
      const notificationSnapshot = await transaction.get(notificationRef);

      if (!notificationSnapshot.exists) {
        throw new Error("Notification does not exist.");
      }

      transaction.delete(notificationRef);
      console.log(`Notification ${notification_id} successfully deleted`);
    });

    return {success: true, message: `Notification ${notification_id} deleted successfully`};
  } catch (error) {
    console.error("Error unsending friend request:", error.message);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

exports.updateFriendRequestStatus = functions.https.onCall(async (data, context) => {
  const {notification_id, status} = data.data;
  if (!notification_id || !status) {
    console.log(
        "notification_id: ", notification_id,
        "status: ", status,
    );
    throw new functions.https.HttpsError(
        "invalid-argument",
        "The notification ID is missing or the status is missing.",
    );
  }

  try {
    await db.runTransaction(async (transaction) => {
      const notificationRef = db.collection("notifications").doc(notification_id);
      const currentSnapshot = await transaction.get(notificationRef);

      if (!currentSnapshot.exists) {
        throw new Error("Notification does not exist.");
      }

      const currentData = currentSnapshot.data();
      if (currentData.status === status) {
        console.log("No change in status; skipping update.");
        return {success: true, message: "No change in status."};
      }

      transaction.update(notificationRef, {status});
      console.log(`Notification status updated to ${status}`);
    });

    return {success: true, message: `Notification status updated to ${status}`};
  } catch (error) {
    console.error("Error updating notification status:", error.message);
    throw new functions.https.HttpsError("internal", error.message);
  }
});
