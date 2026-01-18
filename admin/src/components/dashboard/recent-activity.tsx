"use client";

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { formatDistanceToNow } from "date-fns";

export function RecentActivity({ data }: { data: any[] }) {
    return (
        <Card className="col-span-3 border-white/10 bg-card/50 backdrop-blur-sm">
            <CardHeader>
                <CardTitle>Recent Activity</CardTitle>
                <CardDescription>
                    Latest actions across the platform.
                </CardDescription>
            </CardHeader>
            <CardContent>
                <div className="space-y-8">
                    {data.length === 0 ? (
                        <p className="text-sm text-muted-foreground text-center py-4">No recent activity</p>
                    ) : (
                        data.map((item) => (
                            <div key={item.id} className="flex items-center">
                                <Avatar className="h-9 w-9">
                                    <AvatarImage src={item.user?.image} alt="Avatar" />
                                    <AvatarFallback>{item.user?.initials || "?"}</AvatarFallback>
                                </Avatar>
                                <div className="ml-4 space-y-1">
                                    <p className="text-sm font-medium leading-none">
                                        {item.user?.name} <span className="text-muted-foreground font-normal">{item.action}</span>
                                    </p>
                                    <p className="text-sm text-muted-foreground line-clamp-1" title={item.details}>
                                        {item.details}
                                    </p>
                                </div>
                                <div className="ml-auto font-medium text-xs text-muted-foreground whitespace-nowrap">
                                    {formatDistanceToNow(new Date(item.timestamp), { addSuffix: true })}
                                </div>
                            </div>
                        ))
                    )}
                </div>
            </CardContent>
        </Card>
    );
}
