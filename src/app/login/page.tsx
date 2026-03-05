'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/lib/auth-context';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { Logo } from '@/components/logo';
import { Loader2, Mail, Lock, UserPlus, LogIn } from 'lucide-react';

export default function LoginPage() {
    const [isLogin, setIsLogin] = useState(true);
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [localLoading, setLocalLoading] = useState(false);
    const [errorMsg, setErrorMsg] = useState('');

    const { user, loading: authLoading, signInWithGoogle, signInWithEmailPassword, registerWithEmailPassword } = useAuth();
    const router = useRouter();

    useEffect(() => {
        if (!authLoading && user) {
            router.push('/');
        }
    }, [user, authLoading, router]);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!email || !password) {
            setErrorMsg('Por favor, rellena todos los campos');
            return;
        }
        setLocalLoading(true);
        setErrorMsg('');
        try {
            if (isLogin) {
                await signInWithEmailPassword(email, password);
            } else {
                await registerWithEmailPassword(email, password);
            }
            // Redirect handled by useEffect
        } catch (error: any) {
            console.error(error);
            setErrorMsg('Error de autenticación. Revisa tus credenciales.');
            setLocalLoading(false);
        }
    };

    const handleGoogleLogin = async () => {
        try {
            setLocalLoading(true);
            await signInWithGoogle();
            // Redirect handled by useEffect
        } catch (error) {
            console.error(error);
            setErrorMsg('Error al iniciar sesión con Google.');
            setLocalLoading(false);
        }
    };

    if (authLoading || user) {
        return (
            <div className="flex min-h-screen items-center justify-center bg-background">
                <Logo className="h-16 w-16 text-primary animate-pulse" />
            </div>
        );
    }

    return (
        <div className="flex min-h-screen items-center justify-center bg-background px-4 py-8 relative overflow-hidden">
            {/* Aesthetic background elements */}
            <div className="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] rounded-full bg-primary/20 blur-[120px] pointer-events-none" />
            <div className="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] rounded-full bg-primary/20 blur-[120px] pointer-events-none" />

            <Card className="w-full max-w-md relative z-10 border-primary/10 shadow-2xl glass-panel bg-card/60 backdrop-blur-xl">
                <CardHeader className="space-y-4 text-center pb-6">
                    <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-2xl bg-primary/10 mb-2">
                        <Logo className="h-10 w-10 text-primary" />
                    </div>
                    <div className="space-y-1">
                        <CardTitle className="text-3xl font-headline font-bold text-foreground">
                            {isLogin ? 'Bienvenido a Studiary' : 'Crea tu cuenta'}
                        </CardTitle>
                        <CardDescription className="text-muted-foreground text-sm">
                            {isLogin
                                ? 'Inicia sesión para acceder a tu planificador'
                                : 'Regístrate y organiza tus estudios desde cualquier lugar'}
                        </CardDescription>
                    </div>
                </CardHeader>
                <CardContent className="space-y-6">
                    {errorMsg && (
                        <div className="rounded-md bg-destructive/15 p-3 text-sm text-destructive font-medium text-center">
                            {errorMsg}
                        </div>
                    )}

                    <form onSubmit={handleSubmit} className="space-y-4">
                        <div className="space-y-2">
                            <Label htmlFor="email">Correo electrónico</Label>
                            <div className="relative">
                                <Input
                                    id="email"
                                    type="email"
                                    placeholder="tu@correo.com"
                                    value={email}
                                    onChange={(e) => setEmail(e.target.value)}
                                    className="pl-10 h-12 bg-background/50 border-primary/20 focus-visible:ring-primary/50"
                                    required
                                />
                                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground" />
                            </div>
                        </div>
                        <div className="space-y-2">
                            <Label htmlFor="password">Contraseña</Label>
                            <div className="relative">
                                <Input
                                    id="password"
                                    type="password"
                                    placeholder="••••••••"
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    className="pl-10 h-12 bg-background/50 border-primary/20 focus-visible:ring-primary/50"
                                    required
                                />
                                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground" />
                            </div>
                        </div>

                        <Button
                            type="submit"
                            className="w-full h-12 text-md font-medium shadow-md transition-all hover:scale-[1.02]"
                            disabled={localLoading}
                        >
                            {localLoading ? (
                                <Loader2 className="mr-2 h-5 w-5 animate-spin" />
                            ) : isLogin ? (
                                <>
                                    <LogIn className="mr-2 h-5 w-5" /> Entrar
                                </>
                            ) : (
                                <>
                                    <UserPlus className="mr-2 h-5 w-5" /> Registrarse
                                </>
                            )}
                        </Button>
                    </form>

                    <div className="relative">
                        <div className="absolute inset-0 flex items-center">
                            <span className="w-full border-t border-muted" />
                        </div>
                        <div className="relative flex justify-center text-xs uppercase">
                            <span className="bg-card px-2 text-muted-foreground">
                                O continuar con
                            </span>
                        </div>
                    </div>

                    <Button
                        variant="outline"
                        type="button"
                        className="w-full h-12 bg-background/50 border-primary/20 hover:bg-muted"
                        onClick={handleGoogleLogin}
                        disabled={localLoading}
                    >
                        <svg viewBox="0 0 24 24" className="mr-2 h-5 w-5" aria-hidden="true" focusable="false">
                            <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4" />
                            <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853" />
                            <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05" />
                            <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335" />
                            <path d="M1 1h22v22H1z" fill="none" />
                        </svg>
                        Google
                    </Button>
                </CardContent>
                <CardFooter className="flex flex-col space-y-4">
                    <p className="text-center text-sm text-muted-foreground w-full">
                        {isLogin ? "¿No tienes cuenta? " : "¿Ya tienes cuenta? "}
                        <button
                            type="button"
                            onClick={() => {
                                setIsLogin(!isLogin);
                                setErrorMsg('');
                            }}
                            className="text-primary hover:underline font-semibold"
                        >
                            {isLogin ? "Regístrate" : "Inicia sesión"}
                        </button>
                    </p>
                </CardFooter>
            </Card>
        </div>
    );
}
