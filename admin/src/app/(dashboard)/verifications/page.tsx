"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Check, X, Loader2, AlertCircle } from "lucide-react";
import api from "@/lib/api";
import { Card, CardContent, CardFooter } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";

interface VerificationUser {
    _id: string;
    email: string;
    name?: string;
    department?: string;
    bio?: string;
    verification: {
        idCardUrl: string;
        selfieUrl: string;
        submitted: boolean;
    };
}

export default function VerificationsPage() {
    const queryClient = useQueryClient();

    const { data: users, isLoading } = useQuery<VerificationUser[]>({
        queryKey: ["verifications"],
        queryFn: async () => {
            const res = await api.get("/admin/verifications");
            return res.data;
        },
    });

    const approveMutation = useMutation({
        mutationFn: (id: string) => api.patch(`/admin/users/${id}/approve`),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ["verifications"] });
        },
    });

    const rejectMutation = useMutation({
        mutationFn: (id: string) => api.patch(`/admin/users/${id}/reject`, { reason: "Standard Rejection" }),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ["verifications"] });
        },
    });

    if (isLoading) {
        return <div className="flex h-full items-center justify-center pt-20"><Loader2 className="animate-spin text-primary h-8 w-8" /></div>;
    }

    if (!users || users.length === 0) {
        return (
            <div className="flex flex-col items-center justify-center h-[50vh] text-center space-y-4">
                <div className="bg-muted p-6 rounded-full">
                    <Check className="h-10 w-10 text-muted-foreground" />
                </div>
                <h3 className="text-xl font-semibold">All caught up!</h3>
                <p className="text-muted-foreground">No pending verifications at the moment.</p>
            </div>
        )
    }

    return (
        <div className="space-y-6 animate-in fade-in duration-500">
            <div className="flex items-center justify-between">
                <div>
                    <h2 className="text-3xl font-bold tracking-tight">Verifications</h2>
                    <p className="text-muted-foreground">Review user identification documents.</p>
                </div>
                <Badge variant="secondary" className="text-sm px-3 py-1">
                    {users.length} Pending
                </Badge>
            </div>

            <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
                {users.map((user) => (
                    <Card key={user._id} className="overflow-hidden flex flex-col hover:shadow-lg transition-all duration-200 border-muted/50">
                        <CardContent className="p-0 flex flex-col h-full">
                            <div className="grid grid-cols-2 h-48 shrink-0 relative group">
                                {user.verification.selfieUrl ? (
                                    <div
                                        className="bg-cover bg-center bg-muted"
                                        style={{ backgroundImage: `url(${user.verification.selfieUrl})` }}
                                        title="Selfie"
                                    />
                                ) : <div className="bg-muted flex items-center justify-center text-xs text-muted-foreground">No Selfie</div>}

                                {user.verification.idCardUrl ? (
                                    <div
                                        className="bg-cover bg-center bg-muted border-l border-white/20"
                                        style={{ backgroundImage: `url(${user.verification.idCardUrl})` }}
                                        title="ID Card"
                                    />
                                ) : <div className="bg-muted flex items-center justify-center text-xs text-muted-foreground border-l">No ID</div>}

                                <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-4 text-white">
                                    <span className="text-xs font-medium bg-black/50 px-2 py-1 rounded">View Full Size</span>
                                </div>
                            </div>

                            <div className="p-5 flex flex-col flex-1 gap-2">
                                <div className="flex items-start justify-between">
                                    <div>
                                        <h3 className="font-bold text-lg leading-tight">{user.name || 'No Name'}</h3>
                                        <p className="text-xs text-muted-foreground font-mono mt-0.5">{user.email}</p>
                                    </div>
                                    {user.department && (
                                        <Badge variant="outline" className="text-[10px]">
                                            {user.department}
                                        </Badge>
                                    )}
                                </div>

                                {user.bio && (
                                    <div className="bg-muted/50 p-2 rounded text-xs text-muted-foreground italic line-clamp-2">
                                        "{user.bio}"
                                    </div>
                                )}
                            </div>

                            <CardFooter className="p-4 pt-0 gap-3">
                                <button
                                    onClick={() => rejectMutation.mutate(user._id)}
                                    disabled={rejectMutation.isPending}
                                    className="flex-1 bg-destructive/10 text-destructive hover:bg-destructive/20 h-9 rounded-md flex items-center justify-center font-medium text-sm transition-colors"
                                >
                                    <X className="w-4 h-4 mr-2" /> Reject
                                </button>
                                <button
                                    onClick={() => approveMutation.mutate(user._id)}
                                    disabled={approveMutation.isPending}
                                    className="flex-1 bg-green-600 hover:bg-green-700 text-white h-9 rounded-md flex items-center justify-center font-medium text-sm transition-colors shadow-sm"
                                >
                                    <Check className="w-4 h-4 mr-2" /> Approve
                                </button>
                            </CardFooter>
                        </CardContent>
                    </Card>
                ))}
            </div>
        </div>
    );
}
