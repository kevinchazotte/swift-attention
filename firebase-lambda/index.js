const admin = require('firebase-admin');

// Initialize Firebase Admin (service account JSON as environment variable)
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT))
  });
}

exports.handler = async (event) => {
  try {
    const { token, title = "Button Pressed!", body = "Someone pressed the button" } = JSON.parse(event.body || '{}');
    
    const message = {
      token: token,
      notification: {
        title: title,
        body: body
      }
    };

    const response = await admin.messaging().send(message);
    
    return {
      statusCode: 200,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type"
      },
      body: JSON.stringify({ success: true, messageId: response })
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ success: false, error: error.message })
    };
  }
};
