import type { User } from '@supabase/supabase-js';
import { supabaseClient } from './supabase';

type CloudData = Record<string, unknown>;

const cleanData = (value: unknown) => JSON.parse(JSON.stringify(value));

const canonicalKey = (dataKey: string) => {
    if (dataKey.includes('-events-')) return 'events';
    if (dataKey.includes('-subjects-')) return 'subjects';
    if (dataKey.includes('-schedule-')) return 'schedule';
    if (dataKey.includes('-profiles-')) return 'profiles';
    if (dataKey.includes('-notes-')) return 'notes';
    return dataKey;
};

export const syncToCloud = async (user: User, dataKey: string, appData: unknown) => {
    if (!supabaseClient || !user) return;
    try {
        const { data: row, error: readError } = await supabaseClient
            .from('studiary_data')
            .select('data')
            .eq('user_id', user.id)
            .maybeSingle();
        if (readError) throw readError;

        const existing = row?.data && typeof row.data === 'object'
            ? row.data as CloudData
            : {};
        const key = canonicalKey(dataKey);
        const { error } = await supabaseClient.from('studiary_data').upsert({
            user_id: user.id,
            data: { ...existing, [key]: cleanData(appData) },
            updated_at: new Date().toISOString(),
        }, { onConflict: 'user_id' });
        if (error) throw error;
    } catch (error) {
        console.error('Error syncing Studiary:', error);
    }
};

export const loadFromCloud = async (user: User) => {
    if (!supabaseClient || !user) return null;
    try {
        const { data: row, error } = await supabaseClient
            .from('studiary_data')
            .select('data')
            .eq('user_id', user.id)
            .maybeSingle();
        if (error) throw error;
        return row?.data && typeof row.data === 'object'
            ? row.data as CloudData
            : null;
    } catch (error) {
        console.error('Error loading Studiary:', error);
        return null;
    }
};
