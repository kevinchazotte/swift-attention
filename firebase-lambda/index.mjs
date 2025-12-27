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
    const authHeader = event.headers.Authorization || event.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return { statusCode: 401, body: JSON.stringify({ error: "Unauthorized" }) };
    }
    const idToken = authHeader.split('Bearer ')[1];

    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const senderId = decodedToken.uid;

    const body = JSON.parse(event.body);
    const { title, body: msgBody } = body;

    const senderDoc = await db.collection("users").doc(senderId).get();
    if (!senderDoc.exists) {
      return { 
        statusCode: 404, 
        body: JSON.stringify({ error: "Sender profile not found in database. Please ensure you are signed in." }) 
      };
    }

    const senderData = senderDoc.data();
    const partnerId = senderData.pairedWith;
    if (!partnerId) {
      return { 
        statusCode: 400, 
        body: JSON.stringify({ error: "No partner paired. Please pair with another device first." }) 
      };
    }

    const partnerDoc = await db.collection("users").doc(partnerId).get();
    if (!partnerDoc.exists) {
      return { 
        statusCode: 404, 
        body: JSON.stringify({ error: "Partner profile not found. They may have deleted their account." }) 
      };
    }

    const partnerData = partnerDoc.data();
    const partnerToken = partnerData.token;
    if (!partnerToken) {
      return { 
        statusCode: 400, 
        body: JSON.stringify({ error: "Partner has no active messaging token." }) 
      };
    }

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
