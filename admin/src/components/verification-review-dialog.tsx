"use client"

import * as React from "react"
import { Check, X, AlertCircle, ZoomIn } from "lucide-react"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"

interface VerificationUser {
    _id: string;
    email: string;
    name?: string;
    department?: string;
    bio?: string;
    profileImage?: string;
    verification: {
        idCardUrl: string;
        selfieUrl: string;
        submitted: boolean;
    };
}

interface VerificationReviewDialogProps {
    open: boolean
    onOpenChange: (open: boolean) => void
    user: VerificationUser | null
    onApprove: (id: string) => void
    onReject: (id: string, reason: string) => void
    isProcessing: boolean
}

export function VerificationReviewDialog({
    open,
    onOpenChange,
    user,
    onApprove,
    onReject,
    isProcessing
}: VerificationReviewDialogProps) {
    const [rejectMode, setRejectMode] = React.useState(false)
    const [rejectReason, setRejectReason] = React.useState("ID Card Unclear")
    const [customReason, setCustomReason] = React.useState("")

    if (!user) return null

    const handleReject = () => {
        const finalReason = rejectReason === "other" ? customReason : rejectReason;
        onReject(user._id, finalReason);
        setRejectMode(false);
    };

    const reasons = [
        { value: "ID Card Unclear", label: "ID Card is blurry or unreadable" },
        { value: "Selfie Update Needed", label: "Selfie does not match ID photo" },
        { value: "Information Mismatch", label: "Profile name does not match ID" },
        { value: "Expired Document", label: "ID Card has expired" },
        { value: "other", label: "Other (Please specify)" },
    ];

    return (
        <Dialog open={open} onOpenChange={onOpenChange}>
            <DialogContent className="max-w-4xl h-[80vh] flex flex-col p-0 overflow-hidden bg-background">
                <div className="p-6 border-b border-white/10 flex justify-between items-center bg-muted/20">
                    <div>
                        <DialogTitle className="text-xl">Verification Review</DialogTitle>
                        <DialogDescription>Review documents for {user.name || user.email}</DialogDescription>
                    </div>
                    <Badge variant="outline" className="text-sm">{user.department || "General"}</Badge>
                </div>

                <div className="flex-1 overflow-hidden grid md:grid-cols-2">
                    {/* Left: User Details & ID */}
                    <div className="p-6 border-r border-white/10 overflow-y-auto space-y-6 bg-muted/10">
                        <div className="flex items-center gap-4">
                            <Avatar className="h-16 w-16 border-2 border-primary/20">
                                <AvatarImage src={user.profileImage} />
                                <AvatarFallback className="text-xl">{user.name?.charAt(0).toUpperCase()}</AvatarFallback>
                            </Avatar>
                            <div>
                                <h3 className="font-bold text-lg">{user.name}</h3>
                                <p className="text-muted-foreground">{user.email}</p>
                                <p className="text-xs font-mono text-muted-foreground mt-1">{user._id}</p>
                            </div>
                        </div>

                        <div className="space-y-2">
                            <Label className="uppercase text-xs text-muted-foreground font-semibold tracking-wider">Submitted ID Card</Label>
                            <div className="relative group rounded-lg overflow-hidden border border-white/10 bg-black/40 aspect-video flex items-center justify-center">
                                {user.verification.idCardUrl ? (
                                    <img src={user.verification.idCardUrl} alt="ID Card" className="max-w-full max-h-full object-contain" />
                                ) : (
                                    <span className="text-muted-foreground text-sm">No ID Card</span>
                                )}
                                <div className="absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-colors pointer-events-none" />
                            </div>
                        </div>

                        {user.bio && (
                            <div className="space-y-2">
                                <Label className="uppercase text-xs text-muted-foreground font-semibold tracking-wider">Bio</Label>
                                <div className="p-3 rounded-md bg-muted/40 text-sm italic">{user.bio}</div>
                            </div>
                        )}
                    </div>

                    {/* Right: Selfie & Comparison */}
                    <div className="p-6 overflow-y-auto space-y-6 flex flex-col h-full bg-background">
                        <div className="space-y-2 flex-1">
                            <Label className="uppercase text-xs text-muted-foreground font-semibold tracking-wider">Live Selfie</Label>
                            <div className="relative group rounded-lg overflow-hidden border border-white/10 bg-black/40 aspect-square flex items-center justify-center">
                                {user.verification.selfieUrl ? (
                                    <img src={user.verification.selfieUrl} alt="Selfie" className="max-w-full max-h-full object-cover" />
                                ) : (
                                    <span className="text-muted-foreground text-sm">No Selfie</span>
                                )}
                            </div>
                        </div>

                        {!rejectMode ? (
                            <div className="flex flex-col gap-3 mt-auto pt-6 border-t border-white/10">
                                <h4 className="font-medium text-sm text-center mb-2">Decision</h4>
                                <div className="grid grid-cols-2 gap-4">
                                    <Button variant="destructive" onClick={() => setRejectMode(true)} disabled={isProcessing} className="h-12">
                                        <X className="mr-2 h-5 w-5" /> Reject
                                    </Button>
                                    <Button variant="default" onClick={() => onApprove(user._id)} disabled={isProcessing} className="h-12 bg-green-600 hover:bg-green-700 text-white">
                                        {isProcessing ? <span className="animate-spin mr-2">⏳</span> : <Check className="mr-2 h-5 w-5" />}
                                        Approve
                                    </Button>
                                </div>
                            </div>
                        ) : (
                            <div className="flex flex-col gap-4 mt-auto pt-6 border-t border-white/10 animate-in slide-in-from-bottom-5 fade-in">
                                <div className="flex items-center justify-between">
                                    <h4 className="font-medium text-sm text-red-500 flex items-center"><AlertCircle className="w-4 h-4 mr-2" /> Select Rejection Reason</h4>
                                    <Button variant="ghost" size="sm" onClick={() => setRejectMode(false)}>Cancel</Button>
                                </div>

                                <div className="space-y-3">
                                    <Select value={rejectReason} onValueChange={setRejectReason}>
                                        <SelectTrigger>
                                            <SelectValue placeholder="Select a reason" />
                                        </SelectTrigger>
                                        <SelectContent>
                                            {reasons.map(r => <SelectItem key={r.value} value={r.value}>{r.label}</SelectItem>)}
                                        </SelectContent>
                                    </Select>

                                    {rejectReason === "other" && (
                                        <Textarea
                                            placeholder="Enter specific reason for rejection..."
                                            value={customReason}
                                            onChange={(e) => setCustomReason(e.target.value)}
                                            className="resize-none"
                                        />
                                    )}
                                </div>

                                <Button variant="destructive" onClick={handleReject} disabled={isProcessing} className="w-full">
                                    Confirm Rejection
                                </Button>
                            </div>
                        )}
                    </div>
                </div>
            </DialogContent>
        </Dialog>
    )
}
