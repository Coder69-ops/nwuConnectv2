"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Loader2, Ban, CheckCircle, Search, MoreHorizontal, Eye, X } from "lucide-react";
import api from "@/lib/api";
import { useState } from "react";
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";

interface User {
    _id: string;
    email: string;
    status: 'pending' | 'approved' | 'banned' | 'admin';
    name?: string;
    department?: string;
    bio?: string;
    profileImage?: string; // Added profileImage
    verification?: {
        idCardUrl: string;
        selfieUrl: string;
        submitted: boolean;
    };
}

export default function UsersPage() {
    const queryClient = useQueryClient();
    const [searchTerm, setSearchTerm] = useState("");
    const [selectedUser, setSelectedUser] = useState<User | null>(null);

    const { data: usersData, isLoading } = useQuery<{ users: User[], total: number }>({
        queryKey: ["users"],
        queryFn: async () => {
            const res = await api.get("/admin/users");
            return res.data;
        },
    });

    const banMutation = useMutation({
        mutationFn: (id: string) => api.patch(`/admin/users/${id}/ban`),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ["users"] });
        },
    });

    const unbanMutation = useMutation({
        mutationFn: (id: string) => api.patch(`/admin/users/${id}/unban`),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ["users"] });
        },
    });

    const filteredUsers = usersData?.users.filter(u =>
        u.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
        u.status.includes(searchTerm.toLowerCase()) ||
        (u.name && u.name.toLowerCase().includes(searchTerm.toLowerCase()))
    );

    if (isLoading) {
        return <div className="flex h-full items-center justify-center pt-20"><Loader2 className="animate-spin text-primary h-8 w-8" /></div>;
    }

    return (
        <div className="space-y-6 animate-in fade-in duration-500">
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                <div>
                    <h2 className="text-3xl font-bold tracking-tight">Users</h2>
                    <p className="text-muted-foreground">
                        Manage user accounts and permissions.
                    </p>
                </div>
                <div className="relative w-full sm:w-64">
                    <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                    <input
                        placeholder="Search users..."
                        className="pl-9 flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                    />
                </div>
            </div>

            <Card>
                <CardHeader>
                    <CardTitle>All Users</CardTitle>
                    <CardDescription>
                        A list of all registered users including their name, email, and verification status.
                    </CardDescription>
                </CardHeader>
                <CardContent>
                    <Table>
                        <TableHeader>
                            <TableRow>
                                <TableHead className="w-[300px]">User</TableHead>
                                <TableHead>Status</TableHead>
                                <TableHead>Department</TableHead>
                                <TableHead className="text-right">Actions</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {filteredUsers?.map((user) => (
                                <TableRow key={user._id}>
                                    <TableCell>
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
                                                <span className="font-medium text-sm">{user.name || 'No Name'}</span>
                                                <span className="text-xs text-muted-foreground">{user.email}</span>
                                            </div>
                                        </div>
                                    </TableCell>
                                    <TableCell>
                                        <Badge
                                            variant={
                                                user.status === 'approved' ? 'success' :
                                                    user.status === 'banned' ? 'danger' :
                                                        'warning'
                                            }
                                        >
                                            {user.status}
                                        </Badge>
                                    </TableCell>
                                    <TableCell>
                                        {user.department ? (
                                            <Badge variant="outline" className="font-normal">
                                                {user.department}
                                            </Badge>
                                        ) : (
                                            <span className="text-muted-foreground text-xs">-</span>
                                        )}
                                    </TableCell>
                                    <TableCell className="text-right">
                                        <div className="flex justify-end gap-2">
                                            <button
                                                onClick={() => setSelectedUser(user)}
                                                className="inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-8 w-8 p-0"
                                            >
                                                <Eye className="h-4 w-4" />
                                                <span className="sr-only">View</span>
                                            </button>
                                            {user.status === 'banned' ? (
                                                <button
                                                    onClick={() => unbanMutation.mutate(user._id)}
                                                    className="inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 bg-green-600 text-white hover:bg-green-700 h-8 px-3"
                                                >
                                                    <span className="text-xs">Unban</span>
                                                </button>
                                            ) : (
                                                <button
                                                    onClick={() => banMutation.mutate(user._id)}
                                                    className="inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 border border-input bg-background hover:bg-destructive/10 hover:text-destructive h-8 w-8 p-0"
                                                >
                                                    <Ban className="h-4 w-4" />
                                                    <span className="sr-only">Ban</span>
                                                </button>
                                            )}
                                        </div>
                                    </TableCell>
                                </TableRow>
                            ))}
                        </TableBody>
                    </Table>
                </CardContent>
            </Card>

            {/* View Details Modal */}
            {selectedUser && (
                <div className="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center z-50 p-4 animate-in fade-in duration-200" onClick={() => setSelectedUser(null)}>
                    <div className="bg-card border border-border text-card-foreground rounded-xl max-w-3xl w-full max-h-[90vh] overflow-y-auto shadow-2xl animate-in zoom-in-95 duration-200" onClick={e => e.stopPropagation()}>
                        <div className="p-6 border-b border-border flex justify-between items-center sticky top-0 bg-card z-10">
                            <div>
                                <h3 className="text-2xl font-bold tracking-tight">User Details</h3>
                                <p className="text-sm text-muted-foreground">View user profile and verifications</p>
                            </div>
                            <button onClick={() => setSelectedUser(null)} className="p-2 hover:bg-muted rounded-full transition-colors">
                                <X className="w-5 h-5 text-muted-foreground hover:text-foreground" />
                            </button>
                        </div>
                        <div className="p-6 space-y-8">
                            <div className="grid md:grid-cols-2 gap-8">
                                <div className="space-y-6">
                                    <h4 className="font-semibold text-lg flex items-center gap-2">
                                        <div className="h-1 w-1 bg-primary rounded-full"></div>
                                        Profile Information
                                    </h4>
                                    <div className="space-y-4 bg-muted/30 p-4 rounded-lg border border-border/50">
                                        <div className="flex items-center gap-4 pb-4 border-b border-border/50">
                                            <Avatar className="h-16 w-16 border-2 border-border">
                                                <AvatarImage src={selectedUser.profileImage} />
                                                <AvatarFallback className="text-xl">{selectedUser.name?.charAt(0).toUpperCase() || 'U'}</AvatarFallback>
                                            </Avatar>
                                            <div>
                                                <p className="font-bold text-xl">{selectedUser.name || 'N/A'}</p>
                                                <Badge variant={selectedUser.status === 'approved' ? 'success' : selectedUser.status === 'banned' ? 'danger' : 'outline'}>
                                                    {selectedUser.status}
                                                </Badge>
                                            </div>
                                        </div>
                                        <div className="grid grid-cols-1 gap-4">
                                            <div>
                                                <label className="text-xs font-medium text-muted-foreground uppercase tracking-wider">Email</label>
                                                <p className="text-sm font-medium">{selectedUser.email}</p>
                                            </div>
                                            <div>
                                                <label className="text-xs font-medium text-muted-foreground uppercase tracking-wider">Department</label>
                                                <p className="text-sm font-medium">{selectedUser.department || 'N/A'}</p>
                                            </div>
                                            <div>
                                                <label className="text-xs font-medium text-muted-foreground uppercase tracking-wider">Bio</label>
                                                <p className="text-sm italic text-muted-foreground/80">{selectedUser.bio || 'No bio provided'}</p>
                                            </div>
                                            <div>
                                                <label className="text-xs font-medium text-muted-foreground uppercase tracking-wider">User ID</label>
                                                <p className="font-mono text-xs text-muted-foreground">{selectedUser._id}</p>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div className="space-y-6">
                                    <h4 className="font-semibold text-lg flex items-center gap-2">
                                        <div className="h-1 w-1 bg-primary rounded-full"></div>
                                        Verification Documents
                                    </h4>
                                    <div className="space-y-4">
                                        <div className="group relative overflow-hidden rounded-lg border border-border bg-muted/20">
                                            <div className="absolute top-2 left-2 bg-black/60 text-white text-[10px] px-2 py-0.5 rounded backdrop-blur-md">ID Card</div>
                                            {selectedUser.verification?.idCardUrl ? (
                                                <img src={selectedUser.verification.idCardUrl} alt="ID Card" className="w-full h-48 object-cover transition-transform duration-500 group-hover:scale-105" />
                                            ) : (
                                                <div className="h-48 flex items-center justify-center text-muted-foreground text-sm flex-col gap-2">
                                                    <Ban className="w-8 h-8 opacity-20" />
                                                    No ID Card Uploaded
                                                </div>
                                            )}
                                        </div>
                                        <div className="group relative overflow-hidden rounded-lg border border-border bg-muted/20">
                                            <div className="absolute top-2 left-2 bg-black/60 text-white text-[10px] px-2 py-0.5 rounded backdrop-blur-md">Selfie / Photo</div>
                                            {selectedUser.verification?.selfieUrl ? (
                                                <img src={selectedUser.verification.selfieUrl} alt="Selfie" className="w-full h-48 object-cover transition-transform duration-500 group-hover:scale-105" />
                                            ) : (
                                                <div className="h-48 flex items-center justify-center text-muted-foreground text-sm flex-col gap-2">
                                                    <Ban className="w-8 h-8 opacity-20" />
                                                    No Selfie Uploaded
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div className="p-4 border-t border-border bg-muted/10 flex justify-end gap-2">
                            <button
                                onClick={() => setSelectedUser(null)}
                                className="px-4 py-2 rounded-md text-sm font-medium border border-input bg-background hover:bg-accent hover:text-accent-foreground transition-colors"
                            >
                                Close
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
