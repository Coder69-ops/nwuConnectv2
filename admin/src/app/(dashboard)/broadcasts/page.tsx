"use client";

import { useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { Loader2, Send, Radio } from "lucide-react";
import api from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle, CardDescription, CardFooter } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select";

export default function BroadcastsPage() {
    const [title, setTitle] = useState("");
    const [message, setMessage] = useState("");
    const [target, setTarget] = useState("all");
    const [success, setSuccess] = useState(false);

    const broadcastMutation = useMutation({
        mutationFn: (data: { title: string, message: string, target: string }) => api.patch(`/admin/broadcast`, data),
        onSuccess: () => {
            setSuccess(true);
            setTitle("");
            setMessage("");
            setTarget("all");
            setTimeout(() => setSuccess(false), 3000);
        },
    });

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        broadcastMutation.mutate({ title, message, target });
    };

    return (
        <div className="space-y-6 max-w-4xl mx-auto animate-in fade-in duration-500">
            <div className="flex items-center gap-4">
                <div className="h-12 w-12 rounded-full bg-primary/10 flex items-center justify-center">
                    <Radio className="h-6 w-6 text-primary" />
                </div>
                <div>
                    <h2 className="text-3xl font-bold tracking-tight">Broadcasts</h2>
                    <p className="text-muted-foreground">Send system-wide notifications to your users.</p>
                </div>
            </div>

            <div className="grid md:grid-cols-3 gap-6">
                <Card className="md:col-span-2 border-white/10 bg-card/50 backdrop-blur-sm">
                    <CardHeader>
                        <CardTitle>Compose Notification</CardTitle>
                        <CardDescription>Create a new push notification.</CardDescription>
                    </CardHeader>
                    <CardContent>
                        <form id="broadcast-form" onSubmit={handleSubmit} className="space-y-4">
                            <div className="space-y-2">
                                <Label htmlFor="target">Target Audience</Label>
                                <Select value={target} onValueChange={setTarget}>
                                    <SelectTrigger id="target">
                                        <SelectValue placeholder="Select audience" />
                                    </SelectTrigger>
                                    <SelectContent>
                                        <SelectItem value="all">All Users</SelectItem>
                                        <SelectItem value="student">Students Only</SelectItem>
                                        <SelectItem value="faculty">Faculty Only</SelectItem>
                                        <SelectItem value="staff">Staff Only</SelectItem>
                                    </SelectContent>
                                </Select>
                            </div>

                            <div className="space-y-2">
                                <Label htmlFor="title">Title</Label>
                                <Input
                                    id="title"
                                    value={title}
                                    onChange={(e) => setTitle(e.target.value)}
                                    placeholder="e.g., Maintenance Update"
                                    required
                                />
                            </div>

                            <div className="space-y-2">
                                <Label htmlFor="message">Message Body</Label>
                                <Textarea
                                    id="message"
                                    className="min-h-[150px]"
                                    value={message}
                                    onChange={(e) => setMessage(e.target.value)}
                                    placeholder="Type your message here..."
                                    required
                                />
                            </div>
                        </form>
                    </CardContent>
                    <CardFooter className="flex justify-between border-t border-white/5 pt-6">
                        {success ? (
                            <div className="text-sm text-green-500 font-medium flex items-center">
                                <Send className="w-4 h-4 mr-2" /> Sent successfully!
                            </div>
                        ) : <div></div>}

                        <Button
                            type="submit"
                            form="broadcast-form"
                            disabled={broadcastMutation.isPending || !title || !message}
                            className="w-full md:w-auto min-w-[140px]"
                        >
                            {broadcastMutation.isPending ? <Loader2 className="animate-spin mr-2" /> : <Send className="mr-2 w-4 h-4" />}
                            Send Broadcast
                        </Button>
                    </CardFooter>
                </Card>

                <div className="space-y-6">
                    <Card className="bg-muted/30 border-dashed border-white/10">
                        <CardHeader className="pb-3">
                            <CardTitle className="text-sm uppercase tracking-wider text-muted-foreground">Preview</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="bg-background rounded-xl p-4 shadow-lg border border-border/50 max-w-[300px] mx-auto">
                                <div className="flex items-start gap-3">
                                    <div className="h-10 w-10 rounded-lg bg-primary/20 flex-shrink-0" />
                                    <div className="space-y-1 overflow-hidden">
                                        <div className="font-semibold text-sm truncate">{title || "Notification Title"}</div>
                                        <div className="text-xs text-muted-foreground line-clamp-3">
                                            {message || "Notification message body will appear here..."}
                                        </div>
                                    </div>
                                    <div className="text-[10px] text-muted-foreground flex-shrink-0">now</div>
                                </div>
                            </div>
                        </CardContent>
                    </Card>

                    <div className="p-4 rounded-lg bg-blue-500/10 border border-blue-500/20 text-sm text-blue-400">
                        <h4 className="font-bold mb-1 flex items-center gap-2"><Radio className="w-4 h-4" /> Pro Tip</h4>
                        <p>Broadcasts are delivered instantly to all active devices. Use sparingly to avoid user fatigue.</p>
                    </div>
                </div>
            </div>
        </div>
    );
}
