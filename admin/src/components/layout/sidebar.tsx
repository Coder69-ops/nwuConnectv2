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
    ChevronLeft
} from "lucide-react";
import { cn } from "@/lib/utils";
import { useState } from "react";
import { auth } from "@/lib/firebase";

const routes = [
    {
        label: "Dashboard",
        icon: LayoutDashboard,
        href: "/",
        color: "text-sky-500",
    },
    {
        label: "Verifications",
        icon: UserCheck,
        href: "/verifications",
        color: "text-violet-500",
    },
    {
        label: "Users",
        icon: Users,
        href: "/users",
        color: "text-pink-700",
    },
    {
        label: "Reports",
        icon: Flag,
        href: "/reports",
        color: "text-orange-700",
    },
    {
        label: "Notifications",
        icon: Radio,
        href: "/broadcasts",
        color: "text-emerald-500",
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
    // useRouter needed for guaranteed redirect after logout
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
        <div className={cn(
            "space-y-4 py-4 flex flex-col h-full bg-slate-950 text-white transition-all duration-300",
            collapsed ? "w-[70px]" : "w-72"
        )}>
            <div className="px-3 py-2 flex-1">
                <div className="flex items-center justify-between mb-14 px-2">
                    <Link href="/" className={cn("flex items-center", collapsed && "justify-center w-full")}>
                        <div className="relative w-8 h-8 mr-0 md:mr-4">
                            <div className="w-8 h-8 bg-gradient-to-br from-indigo-500 to-purple-600 rounded-lg flex items-center justify-center font-bold shadow-lg">N</div>
                        </div>
                        {!collapsed && (
                            <h1 className="text-xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-white to-gray-400">
                                NWUC Admin
                            </h1>
                        )}
                    </Link>
                    {!mobile && setCollapsed && !collapsed && (
                        <button onClick={() => setCollapsed(!collapsed)} className="text-zinc-500 hover:text-white">
                            <ChevronLeft className="h-5 w-5" />
                        </button>
                    )}
                </div>

                <div className="space-y-1">
                    {routes.map((route) => (
                        <Link
                            key={route.href}
                            href={route.href}
                            onClick={onClose}
                            className={cn(
                                "text-sm group flex p-3 w-full justify-start font-medium cursor-pointer hover:text-white hover:bg-white/10 rounded-lg transition-all",
                                pathname === route.href ? "text-white bg-white/10" : "text-zinc-400",
                                collapsed && "justify-center px-2"
                            )}
                            title={collapsed ? route.label : undefined}
                        >
                            <div className="flex items-center flex-1">
                                <route.icon className={cn("h-5 w-5", !collapsed && "mr-3", route.color)} />
                                {!collapsed && route.label}
                            </div>
                        </Link>
                    ))}
                </div>
            </div>

            <div className="px-3 py-2 border-t border-white/10 pt-4">
                <div className={cn(
                    "text-sm group flex p-3 w-full justify-start font-medium cursor-pointer hover:text-white hover:bg-white/10 rounded-lg transition text-zinc-400",
                    collapsed && "justify-center"
                )}>
                    <div className="flex items-center flex-1">
                        <Settings className={cn("h-5 w-5", !collapsed && "mr-3")} />
                        {!collapsed && "Settings"}
                    </div>
                </div>
                <div
                    onClick={handleLogout}
                    className={cn(
                        "text-sm group flex p-3 w-full justify-start font-medium cursor-pointer hover:text-red-500 hover:bg-white/10 rounded-lg transition text-zinc-400 mt-1",
                        collapsed && "justify-center"
                    )}>
                    <div className="flex items-center flex-1">
                        <LogOut className={cn("h-5 w-5", !collapsed && "mr-3")} />
                        {!collapsed && "Logout"}
                    </div>
                </div>
            </div>
        </div>
    );
}
