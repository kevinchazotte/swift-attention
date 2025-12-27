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
    // 1. Extract the token from the Authorization header
    const authHeader = event.headers.Authorization || event.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return { statusCode: 401, body: JSON.stringify({ error: "Unauthorized" }) };
    }
    const idToken = authHeader.split('Bearer ')[1];

    // 2. Verify the token to get the ACTUAL senderId
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const senderId = decodedToken.uid; // This is now secure and verified

    const body = JSON.parse(event.body);
    const { title, body: msgBody } = body;

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
    console.error("Auth or Logic Error:", e);
    return {
      statusCode: e.code === 'auth/id-token-expired' ? 401 : 500,
      body: JSON.stringify({ error: e.message }),
    };
  }
};
