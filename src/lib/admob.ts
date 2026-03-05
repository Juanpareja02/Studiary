
import { AdMob, BannerAdSize, BannerAdPosition, BannerAdPluginEvents, AdMobBannerSize } from '@capacitor-community/admob';
import { Capacitor } from '@capacitor/core';

export async function initializeAdMob() {
    if (Capacitor.getPlatform() === 'web') return;

    await AdMob.initialize({});
}

export async function showBanner() {
    if (Capacitor.getPlatform() === 'web') return;

    const options = {
        adId: 'ca-app-pub-3048984943282265/8585318289', // TU ID DE BANNER REAL
        adSize: BannerAdSize.ADAPTIVE_BANNER,
        position: BannerAdPosition.BOTTOM_CENTER,
        margin: 0,
        isTesting: false, // ¡Cuidado! Ya no es modo prueba
    };

    await AdMob.showBanner(options);
}

export async function hideBanner() {
    if (Capacitor.getPlatform() === 'web') return;
    await AdMob.hideBanner();
}
