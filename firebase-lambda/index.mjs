import admin from "firebase-admin";

// Initialize Firebase Admin (service account JSON as environment variable)
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(
      JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)
    ),
  });
}

const db = admin.firestore();

export const handler = async (event, context) => {
  try {
    const body = JSON.parse(event.body);
    const { senderId, title, body: msgBody } = body;

    const senderDoc = await db.collection("users").doc(senderId).get();
    const partnerId = senderDoc.data().pairedWith;
    if (!partnerId) throw new Error("No paired user");

    const partnerDoc = await db.collection("users").doc(partnerId).get();
    const partnerToken = partnerDoc.data().token;

    const message = {
      token: partnerToken,
      notification: { title, body: msgBody },
    };

    const response = await admin.messaging().send(message);

    return {
      statusCode: 200,
      body: JSON.stringify({ success: true, response }),
    };
  } catch (e) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: e.message }),
    };
  }
};
