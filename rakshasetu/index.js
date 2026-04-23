const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendAlertNotification = functions.firestore
  .document("alerts/{alertId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();

    const type = (data.type || "Alert").toLowerCase();

    let targetEmail = "security@demo.com";

    if (type === "fire") {
      targetEmail = "fire@demo.com";
    } else if (type === "medical") {
      targetEmail = "medical@demo.com";
    }

    const usersSnap = await admin
      .firestore()
      .collection("users")
      .where("email", "==", targetEmail)
      .limit(1)
      .get();

    if (usersSnap.empty) return null;

    const token =
      usersSnap.docs[0].data().fcmToken;

    if (!token) return null;

    const message = {
      token: token,
      notification: {
        title:
          "New " +
          data.type +
          " Alert",
        body:
          data.building +
          " • " +
          data.room,
      },
      data: {
        status: "pending",
        type: data.type || "Alert",
      },
    };

    return admin
      .messaging()
      .send(message);
  });