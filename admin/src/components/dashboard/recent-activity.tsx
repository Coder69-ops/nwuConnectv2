"use client";

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";

export function RecentActivity() {
    return (
        <Card className="col-span-3">
            <CardHeader>
                <CardTitle>Recent Activity</CardTitle>
                <CardDescription>
                    Latest actions across the platform.
                </CardDescription>
            </CardHeader>
            <CardContent>
                <div className="space-y-8">
                    <div className="flex items-center">
                        <Avatar className="h-9 w-9">
                            <AvatarImage src="/avatars/01.png" alt="Avatar" />
                            <AvatarFallback>JD</AvatarFallback>
                        </Avatar>
                        <div className="ml-4 space-y-1">
                            <p className="text-sm font-medium leading-none">John Doe verified</p>
                            <p className="text-sm text-muted-foreground">
                                john.doe@example.com
                            </p>
                        </div>
                        <div className="ml-auto font-medium text-sm text-green-500">Verified</div>
                    </div>
                    <div className="flex items-center">
                        <Avatar className="h-9 w-9">
                            <AvatarImage src="/avatars/02.png" alt="Avatar" />
                            <AvatarFallback>JL</AvatarFallback>
                        </Avatar>
                        <div className="ml-4 space-y-1">
                            <p className="text-sm font-medium leading-none">Jane Lee reported post</p>
                            <p className="text-sm text-muted-foreground">
                                Spam content
                            </p>
                        </div>
                        <div className="ml-auto font-medium text-sm text-orange-500">Report</div>
                    </div>
                    <div className="flex items-center">
                        <Avatar className="h-9 w-9">
                            <AvatarImage src="/avatars/03.png" alt="Avatar" />
                            <AvatarFallback>IN</AvatarFallback>
                        </Avatar>
                        <div className="ml-4 space-y-1">
                            <p className="text-sm font-medium leading-none">Isabella Nguyen joined</p>
                            <p className="text-sm text-muted-foreground">
                                isabella.nguyen@email.com
                            </p>
                        </div>
                        <div className="ml-auto font-medium text-sm text-blue-500">+1 User</div>
                    </div>
                    <div className="flex items-center">
                        <Avatar className="h-9 w-9">
                            <AvatarImage src="/avatars/04.png" alt="Avatar" />
                            <AvatarFallback>WK</AvatarFallback>
                        </Avatar>
                        <div className="ml-4 space-y-1">
                            <p className="text-sm font-medium leading-none">William Kim posted</p>
                            <p className="text-sm text-muted-foreground">
                                New announcement
                            </p>
                        </div>
                        <div className="ml-auto font-medium text-sm text-gray-500">2m ago</div>
                    </div>
                </div>
            </CardContent>
        </Card>
    );
}
