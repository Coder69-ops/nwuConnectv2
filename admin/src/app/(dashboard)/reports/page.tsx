"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Loader2 } from "lucide-react";
import api from "@/lib/api";
import { DataTable } from "@/components/ui/data-table";
import { createReportColumns, Report } from "./columns";

export default function ReportsPage() {
    const queryClient = useQueryClient();

    const { data: reports, isLoading } = useQuery<Report[]>({
        queryKey: ["reports"],
        queryFn: async () => {
            const res = await api.get("/admin/reports");
            return res.data;
        },
    });

    const resolveMutation = useMutation({
        mutationFn: (id: string) => api.patch(`/admin/reports/${id}/resolve`),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ["reports"] });
        },
    });

    const dismissMutation = useMutation({
        mutationFn: (id: string) => api.patch(`/admin/reports/${id}/dismiss`),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ["reports"] });
        },
    });

    const banUserMutation = useMutation({
        mutationFn: (userId: string) => api.patch(`/admin/users/${userId}/ban`),
        onSuccess: () => {
            // Maybe show a toast
        },
    });

    const handleResolve = (id: string) => resolveMutation.mutate(id);
    const handleDismiss = (id: string) => dismissMutation.mutate(id);
    const handleBanUser = (userId: string) => banUserMutation.mutate(userId);

    const columns = createReportColumns({
        onResolve: handleResolve,
        onDismiss: handleDismiss,
        onBanUser: handleBanUser
    });

    if (isLoading) {
        return <div className="flex h-full items-center justify-center pt-20"><Loader2 className="animate-spin text-primary h-8 w-8" /></div>;
    }

    return (
        <div className="space-y-6 animate-in fade-in duration-500">
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                <div>
                    <h2 className="text-3xl font-bold tracking-tight">Reports</h2>
                    <p className="text-muted-foreground">
                        Manage user reports and content moderation.
                    </p>
                </div>
            </div>

            <DataTable
                columns={columns}
                data={reports || []}
                searchKey="reason"
            />
        </div>
    );
}
