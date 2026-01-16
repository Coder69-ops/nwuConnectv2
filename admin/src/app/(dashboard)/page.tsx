"use client";

import {
    Card,
    CardContent,
    CardHeader,
    CardTitle,
    CardDescription
} from "@/components/ui/card";
import { Users, UserCheck, Flag, Activity, Loader2, ArrowUpRight } from "lucide-react";
import { useQuery } from "@tanstack/react-query";
import api from "@/lib/api";
import { UserGrowthChart } from "@/components/dashboard/user-growth-chart";
import { RecentActivity } from "@/components/dashboard/recent-activity";

export default function DashboardPage() {
    const { data: stats, isLoading } = useQuery({
        queryKey: ["stats"],
        queryFn: async () => {
            const res = await api.get("/admin/stats");
            return res.data;
        }
    });

    if (isLoading) {
        return <div className="flex h-full items-center justify-center pt-20"><Loader2 className="animate-spin text-primary h-8 w-8" /></div>;
    }

    const statItems = [
        {
            title: "Total Users",
            value: stats?.totalUsers || "2,345", // Mock fallback if api fails
            icon: Users,
            description: "+12% from last month",
            trend: "+12%"
        },
        {
            title: "Pending Verifications",
            value: stats?.pendingVerifications || "12",
            icon: UserCheck,
            description: "Requires attention",
            trend: "high priority"
        },
        {
            title: "Active Reports",
            value: stats?.activeReports || "5",
            icon: Flag,
            description: "-2% from yesterday",
            trend: "-2%"
        },
        {
            title: "Online Now",
            value: stats?.onlineNow || "573",
            icon: Activity,
            description: "+201 since last hour",
            trend: "+201"
        }
    ];

    return (
        <div className="space-y-6 animate-in fade-in duration-500">
            <div className="flex items-center justify-between space-y-2">
                <h2 className="text-3xl font-bold tracking-tight">Dashboard</h2>
                <div className="flex items-center space-x-2">
                    <button className="inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 bg-primary text-primary-foreground shadow hover:bg-primary/90 h-9 px-4 py-2">
                        Download Report
                    </button>
                </div>
            </div>

            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                {statItems.map((stat) => (
                    <Card key={stat.title} className="hover:shadow-lg transition-shadow duration-200">
                        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                            <CardTitle className="text-sm font-medium">
                                {stat.title}
                            </CardTitle>
                            <stat.icon className="h-4 w-4 text-muted-foreground" />
                        </CardHeader>
                        <CardContent>
                            <div className="text-2xl font-bold">{stat.value}</div>
                            <p className="text-xs text-muted-foreground">
                                {stat.description}
                            </p>
                        </CardContent>
                    </Card>
                ))}
            </div>

            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-7">
                <UserGrowthChart />
                <RecentActivity />
            </div>
        </div>
    );
}
