'use client';

import React, { createContext, useContext, useEffect, useState } from 'react';
import type { User } from '@supabase/supabase-js';
import { supabaseClient } from './supabase';

interface AuthContextType {
    user: User | null;
    loading: boolean;
    signInWithGoogle: () => Promise<void>;
    signInWithEmailPassword: (e: string, p: string) => Promise<void>;
    registerWithEmailPassword: (e: string, p: string) => Promise<void>;
    signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType>({
    user: null,
    loading: true,
    signInWithGoogle: async () => { },
    signInWithEmailPassword: async () => { },
    registerWithEmailPassword: async () => { },
    signOut: async () => { },
});

export const useAuth = () => useContext(AuthContext);

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
    const [user, setUser] = useState<User | null>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const client = supabaseClient;
        if (!client) {
            setLoading(false);
            return;
        }

        let mounted = true;
        const loadSession = async () => {
            const { data } = await client.auth.getSession();
            if (mounted) {
                setUser(data.session?.user ?? null);
                setLoading(false);
            }
        };
        void loadSession();

        const { data: listener } = client.auth.onAuthStateChange(
            (_event, session) => {
                if (!mounted) return;
                setUser(session?.user ?? null);
                setLoading(false);
            },
        );

        return () => {
            mounted = false;
            listener.subscription.unsubscribe();
        };
    }, []);

    const signInWithGoogle = async () => {
        if (!supabaseClient) throw new Error('Supabase no está configurado.');
        const { error } = await supabaseClient.auth.signInWithOAuth({
            provider: 'google',
            options: {
                redirectTo: window.location.origin,
            },
        });
        if (error) throw error;
    };

    const signInWithEmailPassword = async (e: string, p: string) => {
        if (!supabaseClient) throw new Error('Supabase no está configurado.');
        const { error } = await supabaseClient.auth.signInWithPassword({
            email: e.trim(),
            password: p,
        });
        if (error) throw error;
    };

    const registerWithEmailPassword = async (e: string, p: string) => {
        if (!supabaseClient) throw new Error('Supabase no está configurado.');
        const { data, error } = await supabaseClient.auth.signUp({
            email: e.trim(),
            password: p,
        });
        if (error) throw error;
        if (!data.session) {
            throw new Error('Cuenta creada. Revisa tu correo para confirmar el acceso.');
        }
    };

    const signOut = async () => {
        if (!supabaseClient) return;
        const { error } = await supabaseClient.auth.signOut();
        if (error) throw error;
    };

    return (
        <AuthContext.Provider value={{ user, loading, signInWithGoogle, signInWithEmailPassword, registerWithEmailPassword, signOut }}>
            {children}
        </AuthContext.Provider>
    );
};
