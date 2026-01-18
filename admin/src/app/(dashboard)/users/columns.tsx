"use client"

import { ColumnDef } from "@tanstack/react-table"
import { ArrowUpDown, MoreHorizontal, Ban, Eye, CheckCircle } from "lucide-react"

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

// This type is used to define the shape of our data.
// You can use a Zod schema here if you want.
export type User = {
    _id: string
    name?: string
    email: string
    status: "pending" | "approved" | "banned" | "admin"
    department?: string
    bio?: string
    profileImage?: string
    verification?: {
        idCardUrl: string
        selfieUrl: string
        submitted: boolean
    }
}

interface ColumnsProps {
    onView: (user: User) => void;
    onBan: (id: string) => void;
    onUnban: (id: string) => void;
}

export const createColumns = ({ onView, onBan, onUnban }: ColumnsProps): ColumnDef<User>[] => [
    {
        accessorKey: "name",
        header: ({ column }) => {
            return (
                <Button
                    variant="ghost"
                    onClick={() => column.toggleSorting(column.getIsSorted() === "asc")}
                >
                    User
                    <ArrowUpDown className="ml-2 h-4 w-4" />
                </Button>
            )
        },
        cell: ({ row }) => {
            const user = row.original;
            return (
                <div className="flex items-center gap-3">
                    <Avatar className="h-9 w-9">
                        {user.profileImage ? (
                            <AvatarImage src={user.profileImage} alt={user.name} />
                        ) : (
                            <AvatarImage src={`https://api.dicebear.com/7.x/avataaars/svg?seed=${user._id}`} />
                        )}
                        <AvatarFallback>{user.name?.charAt(0).toUpperCase() || 'U'}</AvatarFallback>
                    </Avatar>
                    <div className="flex flex-col">
                        <span className="font-medium text-sm text-foreground">{user.name || 'No Name'}</span>
                        <span className="text-xs text-muted-foreground">{user.email}</span>
                    </div>
                </div>
            )
        }
    },
    {
        accessorKey: "status",
        header: "Status",
        cell: ({ row }) => {
            const status = row.getValue("status") as string

            let variant: "default" | "secondary" | "destructive" | "outline" | "success" | "warning" | "danger" = "outline";
            if (status === 'approved') variant = 'success';
            if (status === 'banned') variant = 'danger';
            if (status === 'pending') variant = 'warning';
            if (status === 'admin') variant = 'default';

            return <Badge variant={variant} className="capitalize">{status}</Badge>
        },
    },
    {
        accessorKey: "department",
        header: "Department",
        cell: ({ row }) => {
            return <div className="text-muted-foreground text-sm">{row.getValue("department") || "-"}</div>
        },
    },
    {
        id: "actions",
        cell: ({ row }) => {
            const user = row.original

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
                            <DropdownMenuItem onClick={() => navigator.clipboard.writeText(user._id)}>
                                Copy User ID
                            </DropdownMenuItem>
                            <DropdownMenuSeparator />
                            <DropdownMenuItem onClick={() => onView(user)}>
                                <Eye className="mr-2 h-4 w-4" /> View Details
                            </DropdownMenuItem>
                            {user.status === 'banned' ? (
                                <DropdownMenuItem onClick={() => onUnban(user._id)} className="text-green-600 focus:text-green-600">
                                    <CheckCircle className="mr-2 h-4 w-4" /> Unban User
                                </DropdownMenuItem>
                            ) : (
                                <DropdownMenuItem onClick={() => onBan(user._id)} className="text-red-600 focus:text-red-600">
                                    <Ban className="mr-2 h-4 w-4" /> Ban User
                                </DropdownMenuItem>
                            )}
                        </DropdownMenuContent>
                    </DropdownMenu>
                </div>
            )
        },
    },
]
