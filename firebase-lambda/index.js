const admin = require("firebase-admin");

// Initialize Firebase Admin (service account JSON as environment variable)
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(
      JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)
    ),
  });
}

const db = admin.firestore();

exports.sendNotification = async (req, res) => {
  const { senderId, title, body } = req.body;

  try {
    const senderDoc = await db.collection("users").doc(senderId).get();
    const partnerId = senderDoc.data().pairedWith;
    if (!partnerId) throw new Error("No paired user");

    const partnerDoc = await db.collection("users").doc(partnerId).get();
    const partnerToken = partnerDoc.data().token;

    const message = {
      token: partnerToken,
      notification: { title, body },
    };

    const response = await admin.messaging().send(message);
    res.status(200).send({ success: true, response });
  } catch (e) {
    res.status(500).send({ error: e.message });
  }
};
