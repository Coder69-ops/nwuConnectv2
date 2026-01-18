"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
    LayoutDashboard,
    UserCheck,
    Users,
    Flag,
    Radio,
    LogOut,
    Settings,
    ChevronLeft,
    Menu
} from "lucide-react";
import { cn } from "@/lib/utils";
import { auth } from "@/lib/firebase";
import { motion, AnimatePresence } from "framer-motion";

const routes = [
    {
        label: "Dashboard",
        icon: LayoutDashboard,
        href: "/",
        color: "text-sky-500",
        gradient: "from-sky-400 to-blue-600",
    },
    {
        label: "Verifications",
        icon: UserCheck,
        href: "/verifications",
        color: "text-violet-500",
        gradient: "from-violet-400 to-purple-600",
    },
    {
        label: "Users",
        icon: Users,
        href: "/users",
        color: "text-pink-700",
        gradient: "from-pink-400 to-rose-600",
    },
    {
        label: "Reports",
        icon: Flag,
        href: "/reports",
        color: "text-orange-700",
        gradient: "from-orange-400 to-red-600",
    },
    {
        label: "Broadcasts",
        icon: Radio,
        href: "/broadcasts",
        color: "text-emerald-500",
        gradient: "from-emerald-400 to-green-600",
    },
];

interface SidebarProps {
    collapsed?: boolean;
    setCollapsed?: (val: boolean) => void;
    mobile?: boolean;
    onClose?: () => void;
}

export function Sidebar({ collapsed = false, setCollapsed, mobile, onClose }: SidebarProps) {
    const pathname = usePathname();
    const router = require("next/navigation").useRouter();

    const handleLogout = async () => {
        try {
            await auth.signOut();
            router.push("/login");
        } catch (error) {
            console.error("Logout failed", error);
        }
    };

    return (
        <motion.div
            initial={mobile ? { x: -300 } : false}
            animate={mobile ? { x: 0 } : { width: collapsed ? 80 : 288 }}
            className={cn(
                "relative h-full flex flex-col bg-slate-950/50 backdrop-blur-xl border-r border-slate-800 text-white overflow-hidden",
                mobile ? "w-72" : ""
            )}
        >
            <div className="flex flex-col flex-1 px-3 py-4">
                {/* Logo Section */}
                <div className="flex items-center justify-between mb-10 px-2 mt-2">
                    <Link href="/" className={cn("flex items-center gap-x-3", collapsed && "justify-center w-full")}>
                        <div className="relative w-9 h-9 shrink-0">
                            <div className="w-9 h-9 bg-gradient-to-br from-indigo-500 via-purple-500 to-pink-500 rounded-xl flex items-center justify-center font-bold shadow-lg shadow-indigo-500/20">
                                <span className="text-white text-lg">N</span>
                            </div>
                        </div>
                        <AnimatePresence>
                            {!collapsed && (
                                <motion.div
                                    initial={{ opacity: 0, x: -10 }}
                                    animate={{ opacity: 1, x: 0 }}
                                    exit={{ opacity: 0, x: -10 }}
                                    className="flex flex-col"
                                >
                                    <h1 className="text-xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-white to-slate-400">
                                        NWUC Admin
                                    </h1>
                                    <span className="text-[10px] text-slate-500 font-medium tracking-wider uppercase">Control Panel</span>
                                </motion.div>
                            )}
                        </AnimatePresence>
                    </Link>
                    {!mobile && setCollapsed && !collapsed && (
                        <button
                            onClick={() => setCollapsed(!collapsed)}
                            className="p-1 rounded-lg bg-slate-800/50 hover:bg-slate-800 text-slate-400 hover:text-white transition-colors"
                        >
                            <ChevronLeft className="h-4 w-4" />
                        </button>
                    )}
                </div>

                {/* Routes */}
                <div className="space-y-1.5 flex-1">
                    {routes.map((route) => {
                        const isActive = pathname === route.href;
                        return (
                            <Link
                                key={route.href}
                                href={route.href}
                                onClick={onClose}
                                title={collapsed ? route.label : undefined}
                                className={cn(
                                    "relative group flex items-center p-3 w-full font-medium cursor-pointer rounded-xl transition-all duration-200 overflow-hidden",
                                    isActive
                                        ? "text-white bg-slate-800/40 shadow-sm"
                                        : "text-slate-400 hover:text-white hover:bg-slate-800/20",
                                    collapsed ? "justify-center px-0 py-3" : "justify-start"
                                )}
                            >
                                {isActive && (
                                    <motion.div
                                        layoutId="activeTab"
                                        className="absolute inset-0 border-l-2 border-indigo-500 bg-gradient-to-r from-indigo-500/10 to-transparent"
                                        initial={false}
                                        transition={{ type: "spring", stiffness: 100, damping: 30 }}
                                    />
                                )}
                                <div className="relative flex items-center z-10">
                                    <route.icon
                                        className={cn(
                                            "h-5 w-5 transition-colors",
                                            isActive ? route.color : "group-hover:text-white",
                                            !collapsed && "mr-3"
                                        )}
                                    />
                                    {!collapsed && (
                                        <motion.span
                                            initial={{ opacity: 0 }}
                                            animate={{ opacity: 1 }}
                                            transition={{ delay: 0.1 }}
                                        >
                                            {route.label}
                                        </motion.span>
                                    )}
                                </div>
                            </Link>
                        );
                    })}
                </div>

                {/* Footer Section */}
                <div className="pt-4 mt-auto border-t border-slate-800/50 space-y-1.5">
                    <Link
                        href="/settings"
                        className={cn(
                            "group flex items-center p-3 w-full font-medium cursor-pointer rounded-xl transition-all hover:bg-slate-800/30 text-slate-400 hover:text-white",
                            collapsed ? "justify-center" : "justify-start"
                        )}
                    >
                        <Settings className={cn("h-5 w-5", !collapsed && "mr-3")} />
                        {!collapsed && <span>Settings</span>}
                    </Link>
                    <div
                        onClick={handleLogout}
                        className={cn(
                            "group flex items-center p-3 w-full font-medium cursor-pointer rounded-xl transition-all hover:bg-red-500/10 text-slate-400 hover:text-red-400",
                            collapsed ? "justify-center" : "justify-start"
                        )}
                    >
                        <LogOut className={cn("h-5 w-5", !collapsed && "mr-3")} />
                        {!collapsed && <span>Logout</span>}
                    </div>
                </div>
            </div>
        </motion.div>
    );
}
