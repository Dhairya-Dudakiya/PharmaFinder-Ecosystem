// functions/index.js
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.createRider = functions.https.onCall(async (data, context) => {
  // 1. Authentication Check
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated.",
    );
  }

  const adminDoc = await admin
      .firestore()
      .collection("admins")
      .doc(context.auth.uid)
      .get();

  if (!adminDoc.exists) {
    throw new functions.https.HttpsError(
        "permission-denied",
        "You must be an admin to perform this action.",
    );
  }

  // 2. Data Validation
  const {email, password, name} = data;
  if (!email || !password || !name) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with email, password, and name.",
    );
  }

  try {
    // 3. Create the user in Firebase Auth
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      displayName: name,
    });

    // 4. Create the document in the 'riders' collection
    await admin.firestore().collection("riders").doc(userRecord.uid).set({
      name: name,
      email: email,
      uid: userRecord.uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 5. Return a success message
    return {message: `Successfully created rider ${name} (${email}).`};
  } catch (error) {
    console.error("Error creating new rider:", error);
    throw new functions.https.HttpsError("internal", error.message, error);
  }
});
