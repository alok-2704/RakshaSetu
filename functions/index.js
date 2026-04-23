const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendAlertNotification = functions.firestore
  .document("alerts/{alertId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();

    const type = (data.type || "").toLowerCase();
    const building = data.building || "";
    const floor = data.floor || "";
    const room = data.room || "";

    const usersSnap = await admin
      .firestore()
      .collection("users")
      .where("role", "==", "admin")
      .where("department", "==", type)
      .get();

    const tokens = [];

    usersSnap.forEach((doc) => {
      const token = doc.data().fcmToken;
      if (token) tokens.push(token);
    });

    if (tokens.length === 0) return null;

    const message = {
      notification: {
        title: `New ${type.toUpperCase()} Alert`,
        body: `${building} | Floor ${floor} | ${room}`,
      },
      tokens: tokens,
    };

    await admin.messaging().sendEachForMulticast(message);

    return null;
  });