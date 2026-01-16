"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Loader2, CheckCircle, AlertTriangle, Search, Eye } from "lucide-react";
import api from "@/lib/api";
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { useState } from "react";

interface Report {
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

export default function ReportsPage() {
    const queryClient = useQueryClient();
    const [searchTerm, setSearchTerm] = useState("");

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

    if (isLoading) {
        return <div className="flex h-full items-center justify-center pt-20"><Loader2 className="animate-spin text-primary h-8 w-8" /></div>;
    }

    const filteredReports = reports?.filter((r) =>
        r.reporter?.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        r.reporter?.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        r.reportedUser?.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        r.reason.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <div className="space-y-6 animate-in fade-in duration-500">
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                <div>
                    <h2 className="text-3xl font-bold tracking-tight">Reports</h2>
                    <p className="text-muted-foreground">
                        Manage user reports and content moderation.
                    </p>
                </div>
                <div className="relative w-full sm:w-64">
                    <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                    <input
                        placeholder="Search reports..."
                        className="pl-9 flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                    />
                </div>
            </div>

            <Card>
                <CardHeader>
                    <CardTitle>Recent Reports</CardTitle>
                    <CardDescription>
                        A list of recent user reports requiring attention.
                    </CardDescription>
                </CardHeader>
                <CardContent>
                    <Table>
                        <TableHeader>
                            <TableRow>
                                <TableHead className="w-[200px]">Reporter</TableHead>
                                <TableHead className="w-[200px]">Reported User</TableHead>
                                <TableHead>Reason</TableHead>
                                <TableHead>Status</TableHead>
                                <TableHead className="text-right">Actions</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {filteredReports?.map((report) => (
                                <TableRow key={report._id}>
                                    <TableCell>
                                        <div className="flex items-center gap-2">
                                            <Avatar className="h-6 w-6">
                                                <AvatarImage src={report.reporter?.profileImage} />
                                                <AvatarFallback>{report.reporter?.name?.charAt(0) || "?"}</AvatarFallback>
                                            </Avatar>
                                            <div className="flex flex-col">
                                                <span className="font-medium text-xs">{report.reporter?.name || "Unknown"}</span>
                                                <span className="text-[10px] text-muted-foreground">{report.reporter?.email}</span>
                                            </div>
                                        </div>
                                    </TableCell>
                                    <TableCell>
                                        <div className="flex items-center gap-2">
                                            <Avatar className="h-6 w-6">
                                                <AvatarImage src={report.reportedUser?.profileImage} />
                                                <AvatarFallback>{report.reportedUser?.name?.charAt(0) || "?"}</AvatarFallback>
                                            </Avatar>
                                            <div className="flex flex-col">
                                                <span className="font-medium text-xs">{report.reportedUser?.name || "Unknown"}</span>
                                                <span className="text-[10px] text-muted-foreground">{report.reportedUser?.email}</span>
                                            </div>
                                        </div>
                                    </TableCell>
                                    <TableCell>{report.reason}</TableCell>
                                    <TableCell>
                                        <Badge variant={report.status === 'resolved' ? 'success' : report.status === 'dismissed' ? 'outline' : 'destructive'}>
                                            {report.status === 'resolved' ? (
                                                <span className="flex items-center gap-1">
                                                    <CheckCircle className="w-3 h-3" /> Resolved
                                                </span>
                                            ) : report.status === 'dismissed' ? (
                                                <span className="flex items-center gap-1">
                                                    Dismissed
                                                </span>
                                            ) : (
                                                <span className="flex items-center gap-1">
                                                    <AlertTriangle className="w-3 h-3" /> Open
                                                </span>
                                            )}
                                        </Badge>
                                    </TableCell>
                                    <TableCell className="text-right">
                                        {report.status === 'open' && (
                                            <div className="flex justify-end gap-2">
                                                <button
                                                    onClick={() => resolveMutation.mutate(report._id)}
                                                    disabled={resolveMutation.isPending}
                                                    className="inline-flex items-center justify-center rounded-md text-xs font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 border border-input bg-background hover:bg-green-50 hover:text-green-600 h-7 px-2"
                                                >
                                                    Resolve
                                                </button>
                                                <button
                                                    onClick={() => dismissMutation.mutate(report._id)}
                                                    disabled={dismissMutation.isPending}
                                                    className="inline-flex items-center justify-center rounded-md text-xs font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 border border-input bg-background hover:bg-gray-100 h-7 px-2"
                                                >
                                                    Dismiss
                                                </button>
                                            </div>
                                        )}
                                    </TableCell>
                                </TableRow>
                            ))}
                            {!filteredReports?.length && (
                                <TableRow>
                                    <TableCell colSpan={5} className="h-24 text-center">
                                        No results.
                                    </TableCell>
                                </TableRow>
                            )}
                        </TableBody>
                    </Table>
                </CardContent>
            </Card>
        </div>
    );
}
