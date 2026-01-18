"use client"

import { ColumnDef } from "@tanstack/react-table"
import { MoreHorizontal, Ban, CheckCircle, AlertTriangle, Eye, XCircle } from "lucide-react"

import { Button } from "@/components/ui/button"
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuLabel,
    DropdownMenuSeparator,
    DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { Badge } from "@/components/ui/badge"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"

export type Report = {
    _id: string;
    reporter: {
        _id: string;
        name: string;
        email: string;
        profileImage?: string;
    };
    reportedUser: {
        _id: string;
        name: string;
        email: string;
        profileImage?: string;
    };
    reason: string;
    status: 'open' | 'resolved' | 'dismissed';
    createdAt: string;
}

interface ColumnsProps {
    onResolve: (id: string) => void;
    onDismiss: (id: string) => void;
    onBanUser: (userId: string) => void; // Ban the reported user
}

export const createReportColumns = ({ onResolve, onDismiss, onBanUser }: ColumnsProps): ColumnDef<Report>[] => [
    {
        accessorKey: "reporter",
        header: "Reporter",
        cell: ({ row }) => {
            const reporter = row.original.reporter;
            return (
                <div className="flex items-center gap-2">
                    <Avatar className="h-8 w-8">
                        <AvatarImage src={reporter?.profileImage} />
                        <AvatarFallback>{reporter?.name?.charAt(0) || "?"}</AvatarFallback>
                    </Avatar>
                    <div className="flex flex-col">
                        <span className="font-medium text-sm text-foreground">{reporter?.name || "Unknown"}</span>
                        <span className="text-xs text-muted-foreground">{reporter?.email}</span>
                    </div>
                </div>
            )
        }
    },
    {
        accessorKey: "reportedUser",
        header: "Reported User",
        cell: ({ row }) => {
            const reportedUser = row.original.reportedUser;
            return (
                <div className="flex items-center gap-2">
                    <Avatar className="h-8 w-8">
                        <AvatarImage src={reportedUser?.profileImage} />
                        <AvatarFallback>{reportedUser?.name?.charAt(0) || "?"}</AvatarFallback>
                    </Avatar>
                    <div className="flex flex-col">
                        <span className="font-medium text-sm text-foreground">{reportedUser?.name || "Unknown"}</span>
                        <span className="text-xs text-muted-foreground">{reportedUser?.email}</span>
                    </div>
                </div>
            )
        }
    },
    {
        accessorKey: "reason",
        header: "Reason",
        cell: ({ row }) => <div className="max-w-[200px] truncate" title={row.getValue("reason")}>{row.getValue("reason")}</div>,
    },
    {
        accessorKey: "status",
        header: "Status",
        cell: ({ row }) => {
            const status = row.getValue("status") as string

            let variant: "default" | "secondary" | "destructive" | "outline" | "success" | "warning" | "danger" = "outline";
            let icon = <AlertTriangle className="w-3 h-3 mr-1" />;

            if (status === 'resolved') {
                variant = 'success';
                icon = <CheckCircle className="w-3 h-3 mr-1" />;
            } else if (status === 'dismissed') {
                variant = 'secondary';
                icon = <XCircle className="w-3 h-3 mr-1" />;
            } else {
                variant = 'destructive'; // Open reports are urgent
            }

            return (
                <Badge variant={variant} className="capitalize flex w-fit items-center">
                    {icon} {status}
                </Badge>
            )
        },
    },
    {
        accessorKey: "createdAt",
        header: "Date",
        cell: ({ row }) => {
            return <span className="text-xs text-muted-foreground">{new Date(row.getValue("createdAt")).toLocaleDateString()}</span>
        }
    },
    {
        id: "actions",
        cell: ({ row }) => {
            const report = row.original

            return (
                <div className="text-right">
                    <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                            <Button variant="ghost" className="h-8 w-8 p-0">
                                <span className="sr-only">Open menu</span>
                                <MoreHorizontal className="h-4 w-4" />
                            </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end">
                            <DropdownMenuLabel>Actions</DropdownMenuLabel>

                            {report.status === 'open' && (
                                <>
                                    <DropdownMenuItem onClick={() => onResolve(report._id)} className="text-green-600 focus:text-green-600">
                                        <CheckCircle className="mr-2 h-4 w-4" /> Resolve & Close
                                    </DropdownMenuItem>
                                    <DropdownMenuItem onClick={() => onDismiss(report._id)}>
                                        <XCircle className="mr-2 h-4 w-4" /> Dismiss Report
                                    </DropdownMenuItem>
                                    <DropdownMenuSeparator />
                                </>
                            )}

                            <DropdownMenuItem onClick={() => onBanUser(report.reportedUser._id)} className="text-red-600 focus:text-red-600">
                                <Ban className="mr-2 h-4 w-4" /> Ban Reported User
                            </DropdownMenuItem>
                        </DropdownMenuContent>
                    </DropdownMenu>
                </div>
            )
        },
    },
]
