"use client";

import { useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { Loader2, Send } from "lucide-react";
import api from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";

export default function BroadcastsPage() {
    const [title, setTitle] = useState("");
    const [message, setMessage] = useState("");
    const [success, setSuccess] = useState(false);

    const broadcastMutation = useMutation({
        mutationFn: (data: { title: string, message: string }) => api.patch(`/admin/broadcast`, data),
        onSuccess: () => {
            setSuccess(true);
            setTitle("");
            setMessage("");
            setTimeout(() => setSuccess(false), 3000);
        },
    });

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        broadcastMutation.mutate({ title, message });
    };

    return (
        <div className="space-y-6 max-w-2xl mx-auto">
            <h2 className="text-3xl font-bold tracking-tight">Notifications</h2>

            <Card>
                <CardHeader>
                    <CardTitle>Send Push Notification</CardTitle>
                    <CardDescription>Send a system-wide notification to all users.</CardDescription>
                </CardHeader>
                <CardContent>
                    <form onSubmit={handleSubmit} className="space-y-4">
                        <div className="space-y-2">
                            <label className="text-sm font-medium">Title</label>
                            <input
                                className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                                value={title}
                                onChange={(e) => setTitle(e.target.value)}
                                placeholder="Maintenance Update"
                                required
                            />
                        </div>
                        <div className="space-y-2">
                            <label className="text-sm font-medium">Message Body</label>
                            <textarea
                                className="flex min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                                value={message}
                                onChange={(e) => setMessage(e.target.value)}
                                placeholder="We will be undergoing maintenance..."
                                required
                            />
                        </div>

                        {success && (
                            <div className="p-3 bg-green-100 text-green-800 rounded text-sm">
                                Broadcast sent successfully!
                            </div>
                        )}

                        <button
                            type="submit"
                            disabled={broadcastMutation.isPending}
                            className="w-full bg-primary text-primary-foreground hover:bg-primary/90 h-10 px-4 py-2 rounded-md flex items-center justify-center font-medium"
                        >
                            {broadcastMutation.isPending ? <Loader2 className="animate-spin mr-2" /> : <Send className="mr-2 w-4 h-4" />}
                            Send Broadcast
                        </button>
                    </form>
                </CardContent>
            </Card>
        </div>
    );
}
