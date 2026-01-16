"use client";

import { useState } from "react";
import { Sidebar } from "@/components/layout/sidebar";
import { Header } from "@/components/layout/header";
import { cn } from "@/lib/utils";

export default function DashboardLayout({
    children,
}: {
    children: React.ReactNode;
}) {
    const [isSidebarOpen, setIsSidebarOpen] = useState(false);
    const [collapsed, setCollapsed] = useState(false);

    return (
        <div className="h-full bg-gray-50 dark:bg-[#020817] relative">
            {/* Desktop Sidebar */}
            <div className={cn(
                "hidden md:flex h-full flex-col fixed inset-y-0 z-50 transition-all duration-300",
                collapsed ? "w-[70px]" : "w-72"
            )}>
                <Sidebar collapsed={collapsed} setCollapsed={setCollapsed} />
            </div>

            {/* Mobile Sidebar Overlay */}
            {isSidebarOpen && (
                <div
                    className="fixed inset-0 z-40 bg-black/50 md:hidden backdrop-blur-sm transition-opacity"
                    onClick={() => setIsSidebarOpen(false)}
                />
            )}

            {/* Mobile Sidebar */}
            <div className={cn(
                "fixed inset-y-0 left-0 z-50 w-72 bg-gray-900 transition-transform duration-300 md:hidden",
                isSidebarOpen ? "translate-x-0" : "-translate-x-full"
            )}>
                <Sidebar mobile onClose={() => setIsSidebarOpen(false)} />
            </div>

            <main className={cn(
                "h-full transition-all duration-300 flex flex-col",
                collapsed ? "md:pl-[70px]" : "md:pl-72"
            )}>
                <Header onMenuClick={() => setIsSidebarOpen(true)} />
                <div className="flex-1 overflow-y-auto p-4 md:p-8">
                    {children}
                </div>
            </main>
        </div>
    );
}
