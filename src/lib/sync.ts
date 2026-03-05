import { doc, getDoc, setDoc, serverTimestamp } from 'firebase/firestore';
import { db } from './firebase';
import { User } from 'firebase/auth';

export const syncToFirestore = async (user: User, dataKey: string, appData: any) => {
    if (!db || !user) return;
    const userRef = doc(db, 'users', user.uid);
    try {
        // Sanitize data before sending to Firestore (e.g. remove undefined / map Dates to ISO strings)
        // Actually, JSON.parse(JSON.stringify()) is a quick way to clean up undefined values for Firestore
        const cleanData = JSON.parse(JSON.stringify(appData));
        await setDoc(userRef, {
            data: {
                [dataKey]: cleanData
            },
            updatedAt: serverTimestamp()
        }, { merge: true });
    } catch (error) {
        console.error("Error syncing to Firestore:", error);
    }
};

export const loadFromFirestore = async (user: User) => {
    if (!db || !user) return null;
    const userRef = doc(db, 'users', user.uid);
    try {
        const docSnap = await getDoc(userRef);
        if (docSnap.exists()) {
            return docSnap.data().data;
        }
    } catch (error) {
        console.error("Error loading from Firestore:", error);
    }
    return null;
};
