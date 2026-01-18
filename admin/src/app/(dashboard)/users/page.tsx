"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Loader2, Ban, X } from "lucide-react";
import api from "@/lib/api";
import { useState } from "react";
import { DataTable } from "@/components/ui/data-table";
import { createColumns, User } from "./columns";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";

export default function UsersPage() {
    const queryClient = useQueryClient();
    const [selectedUser, setSelectedUser] = useState<User | null>(null);

    const { data: usersData, isLoading } = useQuery<{ users: User[], total: number }>({
        queryKey: ["users"],
        queryFn: async () => {
            const res = await api.get("/admin/users", { params: { limit: 1000 } });
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

    const handleView = (user: User) => {
        setSelectedUser(user);
    };

    const handleBan = (id: string) => {
        banMutation.mutate(id);
    };

    const handleUnban = (id: string) => {
        unbanMutation.mutate(id);
    };

    const columns = createColumns({
        onView: handleView,
        onBan: handleBan,
        onUnban: handleUnban
    });

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
            </div>

            <DataTable
                columns={columns}
                data={usersData?.users || []}
                searchKey="name"
            />

            {/* View Details Modal */}
            {selectedUser && (
                <div className="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center z-50 p-4 animate-in fade-in duration-200" onClick={() => setSelectedUser(null)}>
                    <div className="bg-card border border-white/10 text-card-foreground rounded-xl max-w-3xl w-full max-h-[90vh] overflow-y-auto shadow-2xl animate-in zoom-in-95 duration-200 relative" onClick={e => e.stopPropagation()}>
                        <div className="p-6 border-b border-white/10 flex justify-between items-center sticky top-0 bg-card/95 backdrop-blur z-10">
                            <div>
                                <h3 className="text-2xl font-bold tracking-tight">User Details</h3>
                                <p className="text-sm text-muted-foreground">View user profile and verifications</p>
                            </div>
                            <button onClick={() => setSelectedUser(null)} className="p-2 hover:bg-white/10 rounded-full transition-colors">
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
                                    <div className="space-y-4 bg-muted/30 p-4 rounded-lg border border-white/10">
                                        <div className="flex items-center gap-4 pb-4 border-b border-white/10">
                                            <Avatar className="h-16 w-16 border-2 border-white/10">
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
                                        <div className="group relative overflow-hidden rounded-lg border border-white/10 bg-muted/20">
                                            <div className="absolute top-2 left-2 bg-black/60 text-white text-[10px] px-2 py-0.5 rounded backdrop-blur-md z-10">ID Card</div>
                                            {selectedUser.verification?.idCardUrl ? (
                                                <div className="aspect-video w-full relative">
                                                    <img src={selectedUser.verification.idCardUrl} alt="ID Card" className="absolute inset-0 w-full h-full object-cover transition-transform duration-500 group-hover:scale-105" />
                                                </div>
                                            ) : (
                                                <div className="aspect-video flex items-center justify-center text-muted-foreground text-sm flex-col gap-2">
                                                    <Ban className="w-8 h-8 opacity-20" />
                                                    No ID Card Uploaded
                                                </div>
                                            )}
                                        </div>
                                        <div className="group relative overflow-hidden rounded-lg border border-white/10 bg-muted/20">
                                            <div className="absolute top-2 left-2 bg-black/60 text-white text-[10px] px-2 py-0.5 rounded backdrop-blur-md z-10">Selfie / Photo</div>
                                            {selectedUser.verification?.selfieUrl ? (
                                                <div className="aspect-video w-full relative">
                                                    <img src={selectedUser.verification.selfieUrl} alt="Selfie" className="absolute inset-0 w-full h-full object-cover transition-transform duration-500 group-hover:scale-105" />
                                                </div>
                                            ) : (
                                                <div className="aspect-video flex items-center justify-center text-muted-foreground text-sm flex-col gap-2">
                                                    <Ban className="w-8 h-8 opacity-20" />
                                                    No Selfie Uploaded
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
