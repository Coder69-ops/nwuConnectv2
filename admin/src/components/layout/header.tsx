"use client";

import { Bell, Menu, Search, User } from "lucide-react";
import { cn } from "@/lib/utils";

interface HeaderProps {
    onMenuClick: () => void;
}

export function Header({ onMenuClick }: HeaderProps) {
    return (
        <header className="sticky top-0 z-30 flex h-16 w-full items-center border-b bg-background/95 px-4 shadow-sm backdrop-blur supports-[backdrop-filter]:bg-background/60">
            <div className="flex items-center gap-4">
                <button
                    onClick={onMenuClick}
                    className="inline-flex items-center justify-center rounded-md p-2 text-muted-foreground hover:bg-accent hover:text-accent-foreground md:hidden"
                >
                    <Menu className="h-6 w-6" />
                    <span className="sr-only">Toggle Menu</span>
                </button>
                <div className="hidden md:flex items-center gap-2">
                    <div className="h-8 w-8 bg-primary rounded-lg flex items-center justify-center">
                        <span className="text-primary-foreground font-bold">N</span>
                    </div>
                    <span className="font-bold text-lg hidden lg:block">NWUC Admin</span>
                </div>
            </div>

            <div className="flex flex-1 items-center justify-end gap-4">
                <div className="w-full flex-1 md:w-auto md:flex-none">
                    <div className="relative">
                        <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                        <input
                            type="search"
                            placeholder="Search..."
                            className="flex h-9 w-full rounded-md border border-input bg-background pl-8 pr-3 py-1 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 md:w-[200px] lg:w-[300px]"
                        />
                    </div>
                </div>

                <button className="relative inline-flex items-center justify-center rounded-md p-2 text-muted-foreground hover:bg-accent hover:text-accent-foreground">
                    <Bell className="h-5 w-5" />
                    <span className="absolute top-1.5 right-1.5 h-2 w-2 rounded-full bg-red-600" />
                    <span className="sr-only">Notifications</span>
                </button>

                <div className="h-8 w-8 rounded-full bg-accent flex items-center justify-center border mr-2">
                    <User className="h-4 w-4" />
                </div>
            </div>
        </header>
    );
}
