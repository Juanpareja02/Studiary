import { initializeApp, getApps, getApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

const firebaseConfig = {
    apiKey: "AIzaSyDRf41wP6B9IaIJNXCAW_mZu4Pdiwi5Zeg",
    authDomain: "studiary-app-2026.firebaseapp.com",
    projectId: "studiary-app-2026",
    storageBucket: "studiary-app-2026.firebasestorage.app",
    messagingSenderId: "36420802867",
    appId: "1:36420802867:web:bd566843e6708f20940646"
};

const app = !getApps().length ? initializeApp(firebaseConfig) : getApp();
const auth = getAuth(app);
const db = getFirestore(app);

export { app, auth, db };
