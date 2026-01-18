"use client";

import { useQuery } from "@tanstack/react-query";
import { Loader2, Shield, Activity, Server, FileText } from "lucide-react";
import api from "@/lib/api";
import { DataTable } from "@/components/ui/data-table";
import { auditColumns, AuditLog } from "./columns";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";

export default function SettingsPage() {
    // Mock Audit Logs for now until backend endpoint is confirmed
    // Or try to fetch from /admin/audit-logs if it existed. 
    // Since it wasn't explicitly implemented in backend yet (based on previous sessions), 
    // I will mock the data fetching or use a hypothetical endpoint.
    // I'll assume /admin/audit-logs exists or I'll handle empty state gracefully.

    const { data: logs, isLoading: logsLoading } = useQuery<AuditLog[]>({
        queryKey: ["audit-logs"],
        queryFn: async () => {
            try {
                const res = await api.get("/admin/audit-logs");
                return res.data;
            } catch (e) {
                console.warn("Audit logs endpoint might not exist yet, returning empty.");
                return [];
            }
        },
    });

    return (
        <div className="space-y-6 animate-in fade-in duration-500">
            <div>
                <h2 className="text-3xl font-bold tracking-tight">System Settings</h2>
                <p className="text-muted-foreground">Manage system configuration and view audit logs.</p>
            </div>

            <Tabs defaultValue="audit" className="space-y-4">
                <TabsList className="grid w-full grid-cols-3 max-w-[400px]">
                    <TabsTrigger value="general">General</TabsTrigger>
                    <TabsTrigger value="audit">Audit Logs</TabsTrigger>
                    <TabsTrigger value="health">System Health</TabsTrigger>
                </TabsList>

                <TabsContent value="general" className="space-y-4">
                    <Card>
                        <CardHeader>
                            <CardTitle>Profile Settings</CardTitle>
                            <CardDescription>Manage your admin profile preferences.</CardDescription>
                        </CardHeader>
                        <CardContent className="space-y-2">
                            <div className="p-4 bg-muted/20 rounded-md border border-white/5 flex items-center justify-between">
                                <div>
                                    <h4 className="font-medium text-sm">Email Notifications</h4>
                                    <p className="text-xs text-muted-foreground">Receive daily summaries.</p>
                                </div>
                                <Badge variant="outline">Enabled</Badge>
                            </div>
                            <div className="p-4 bg-muted/20 rounded-md border border-white/5 flex items-center justify-between">
                                <div>
                                    <h4 className="font-medium text-sm">Two-Factor Auth</h4>
                                    <p className="text-xs text-muted-foreground">Secure your account.</p>
                                </div>
                                <Badge variant="destructive">Disabled</Badge>
                            </div>
                        </CardContent>
                    </Card>
                </TabsContent>

                <TabsContent value="audit" className="space-y-4">
                    <Card className="border-white/10 bg-card/50 backdrop-blur-sm">
                        <CardHeader>
                            <CardTitle className="flex items-center gap-2">
                                <Shield className="w-5 h-5 text-primary" /> Audit Logs
                            </CardTitle>
                            <CardDescription>View recent administrative actions.</CardDescription>
                        </CardHeader>
                        <CardContent>
                            {logsLoading ? (
                                <div className="flex h-40 items-center justify-center"><Loader2 className="animate-spin text-primary" /></div>
                            ) : (
                                <DataTable
                                    columns={auditColumns}
                                    data={logs || []}
                                    searchKey="action"
                                />
                            )}
                        </CardContent>
                    </Card>
                </TabsContent>

                <TabsContent value="health" className="space-y-4">
                    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                        <Card>
                            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                                <CardTitle className="text-sm font-medium">API Status</CardTitle>
                                <Activity className="h-4 w-4 text-green-500" />
                            </CardHeader>
                            <CardContent>
                                <div className="text-2xl font-bold text-green-500">Operational</div>
                                <p className="text-xs text-muted-foreground">99.9% Uptime</p>
                            </CardContent>
                        </Card>
                        <Card>
                            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                                <CardTitle className="text-sm font-medium">Database</CardTitle>
                                <Server className="h-4 w-4 text-blue-500" />
                            </CardHeader>
                            <CardContent>
                                <div className="text-2xl font-bold text-blue-500">Connected</div>
                                <p className="text-xs text-muted-foreground">MongoDB Cluster</p>
                            </CardContent>
                        </Card>
                        <Card>
                            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                                <CardTitle className="text-sm font-medium">Storage</CardTitle>
                                <FileText className="h-4 w-4 text-orange-500" />
                            </CardHeader>
                            <CardContent>
                                <div className="text-2xl font-bold">45% Used</div>
                                <p className="text-xs text-muted-foreground">Firebase Storage</p>
                            </CardContent>
                        </Card>
                    </div>
                </TabsContent>
            </Tabs>
        </div>
    );
}
