"use client";

import { createContext, useContext, useEffect, useState } from "react";
import { User, onAuthStateChanged } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { useRouter, usePathname } from "next/navigation";
import { Loader2 } from "lucide-react";

interface AuthContextType {
    user: User | null;
    loading: boolean;
}

const AuthContext = createContext<AuthContextType>({
    user: null,
    loading: true,
});

export const useAuth = () => useContext(AuthContext);

export function AuthProvider({ children }: { children: React.ReactNode }) {
    const [user, setUser] = useState<User | null>(null);
    const [loading, setLoading] = useState(true);
    const router = useRouter();
    const pathname = usePathname();

    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, (user) => {
            setUser(user);
            setLoading(false);

            if (!user && pathname !== "/login") {
                router.push("/login"); // Redirect to login if not authenticated and not already there
            } else if (user && pathname === "/login") {
                router.push("/"); // Redirect to dashboard if authenticated and on login page
            }
        });

        return () => unsubscribe();
    }, [pathname, router]);

    return (
        <AuthContext.Provider value={{ user, loading }}>
            {loading ? (
                <div className="flex bg-background h-screen w-full items-center justify-center">
                    <Loader2 className="animate-spin text-primary h-8 w-8" />
                </div>
            ) : (
                // Strict check: Only render children if user exists OR we are on the public login page
                // If not logged in and not on login page, render nothing (while useEffect redirects)
                (!user && pathname !== "/login") ? null : children
            )}
        </AuthContext.Provider>
    );
}
