"use client"

import { ColumnDef } from "@tanstack/react-table"
import { Badge } from "@/components/ui/badge"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"

export type AuditLog = {
    _id: string;
    action: string;
    details: string;
    performedBy: {
        _id: string;
        name: string;
        email: string;
        profileImage?: string;
    };
    createdAt: string;
}

export const auditColumns: ColumnDef<AuditLog>[] = [
    {
        accessorKey: "action",
        header: "Action",
        cell: ({ row }) => <span className="font-medium text-sm">{row.getValue("action")}</span>,
    },
    {
        accessorKey: "details",
        header: "Details",
        cell: ({ row }) => <span className="text-muted-foreground text-sm line-clamp-1" title={row.getValue("details")}>{row.getValue("details")}</span>,
    },
    {
        accessorKey: "performedBy",
        header: "Performed By",
        cell: ({ row }) => {
            const user = row.original.performedBy;
            return (
                <div className="flex items-center gap-2">
                    <Avatar className="h-6 w-6">
                        <AvatarImage src={user?.profileImage} />
                        <AvatarFallback className="text-[10px]">{user?.name?.charAt(0) || "?"}</AvatarFallback>
                    </Avatar>
                    <span className="text-sm">{user?.name || user?.email || "System"}</span>
                </div>
            )
        }
    },
    {
        accessorKey: "createdAt",
        header: "Timestamp",
        cell: ({ row }) => <span className="text-xs text-muted-foreground font-mono">{new Date(row.getValue("createdAt")).toLocaleString()}</span>,
    },
]
