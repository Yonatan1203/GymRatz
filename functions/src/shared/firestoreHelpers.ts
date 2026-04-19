import * as admin from "firebase-admin";

/**
 * Delete all documents in a subcollection under a user document.
 * Uses batched deletes to stay within Firestore limits.
 */
export async function deleteSubcollection(
  firestore: admin.firestore.Firestore,
  uid: string,
  subcollection: string,
): Promise<number> {
  const collRef = firestore
    .collection("users")
    .doc(uid)
    .collection(subcollection);

  let deleted = 0;
  const batchSize = 500;

  let query = collRef.limit(batchSize);
  let snapshot = await query.get();

  while (!snapshot.empty) {
    const batch = firestore.batch();
    for (const doc of snapshot.docs) {
      batch.delete(doc.ref);
    }
    await batch.commit();
    deleted += snapshot.size;

    if (snapshot.size < batchSize) break;
    snapshot = await query.get();
  }

  return deleted;
}
