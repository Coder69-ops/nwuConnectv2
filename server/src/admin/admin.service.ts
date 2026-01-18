import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User, UserDocument } from '../schemas/user.schema';
import { Report, ReportDocument } from '../schemas/report.schema';
import { AuditLog, AuditLogDocument } from '../schemas/audit-log.schema';
import { Notification, NotificationDocument } from '../schemas/notification.schema';

@Injectable()
export class AdminService {
    constructor(
        @InjectModel(User.name) private userModel: Model<UserDocument>,
        @InjectModel(Report.name) private reportModel: Model<ReportDocument>,
        @InjectModel(AuditLog.name) private auditLogModel: Model<AuditLogDocument>,
        @InjectModel(Notification.name) private notificationModel: Model<NotificationDocument>,
    ) { }

    private async logAction(action: string, details: string, performedBy: string = 'system') {
        // In a real app, performedBy would come from the authenticated admin's ID
        // For now we might need to assume a system action or pass the ID from controller
        await this.auditLogModel.create({
            action,
            details,
            // performedBy: null, // Removing explicit null to avoid type error
            metadata: { timestamp: new Date() }
        });
    }

    async getStats() {
        const totalUsers = await this.userModel.countDocuments();
        const pendingVerifications = await this.userModel.countDocuments({
            status: 'pending',
            'verification.submitted': true
        });
        const activeReports = await this.reportModel.countDocuments({ status: 'open' });
        const onlineNow = 573; // Still mocked as we don't have socket gateway hooked up here yet

        return {
            totalUsers,
            pendingVerifications,
            activeReports,
            onlineNow
        };
    }

    async getVerifications() {
        return this.userModel.find({
            status: 'pending',
            'verification.submitted': true
        }).exec();
    }

    async getAllUsers(limit: number = 20, skip: number = 0) {
        const users = await this.userModel.find()
            .sort({ createdAt: -1 })
            .limit(limit)
            .skip(skip)
            .exec();
        const total = await this.userModel.countDocuments();
        return { users, total };
    }

    async approveUser(id: string) {
        const user = await this.userModel.findByIdAndUpdate(id, { status: 'approved' }, { new: true });
        if (!user) throw new NotFoundException('User not found');
        await this.logAction('approve_user', `Approved user ${user.email}`);
        return user;
    }

    async rejectUser(id: string, reason: string) {
        const user = await this.userModel.findByIdAndUpdate(id, {
            'verification.submitted': false,
        }, { new: true });

        if (!user) throw new NotFoundException('User not found');

        // Notify user
        await this.notificationModel.create({
            userId: user.firebaseUid,
            title: "Verification Rejected",
            body: `Your verification was rejected: ${reason}`,
            isRead: false
        });

        await this.logAction('reject_user', `Rejected verification for ${user.email}: ${reason}`);
        return user;
    }

    async banUser(id: string) {
        const user = await this.userModel.findByIdAndUpdate(id, { status: 'banned' }, { new: true });
        if (!user) throw new NotFoundException('User not found');
        await this.logAction('ban_user', `Banned user ${user.email}`);
        return user;
    }

    async unbanUser(id: string) {
        const user = await this.userModel.findByIdAndUpdate(id, { status: 'approved' }, { new: true });
        if (!user) throw new NotFoundException('User not found');
        await this.logAction('unban_user', `Unbanned user ${user.email}`);
        return user;
    }

    async getReports() {
        return this.reportModel.find()
            .populate('reporter', 'name email profileImage')
            .populate('reportedUser', 'name email profileImage')
            .sort({ createdAt: -1 })
            .exec();
    }

    async resolveReport(id: string) {
        await this.logAction('resolve_report', `Resolved report ${id}`);
        return this.reportModel.findByIdAndUpdate(id, { status: 'resolved' }, { new: true });
    }

    async dismissReport(id: string) {
        await this.logAction('dismiss_report', `Dismissed report ${id}`);
        return this.reportModel.findByIdAndUpdate(id, { status: 'dismissed' }, { new: true });
    }

    async sendBroadcast(title: string, message: string, target: string = 'all') {
        // 1. Find target users
        let query = {};
        if (target === 'student' || target === 'faculty' || target === 'staff') {
            query = { role: target }; // Assuming role field holds this info, or department
        }

        // 2. Create In-App Notifications for all matching users
        const users = await this.userModel.find(query).select('firebaseUid').exec();

        const notifications = users.map(user => ({
            userId: user.firebaseUid,
            title,
            body: message,
            isRead: false,
            createdAt: new Date(),
            updatedAt: new Date()
        }));

        if (notifications.length > 0) {
            await this.notificationModel.insertMany(notifications);
        }

        console.log(`[BROADCAST] Sent "${title}" to ${users.length} users (Target: ${target})`);

        await this.logAction('broadcast_sent', `Sent broadcast "${title}" to ${target} (${users.length} users)`);

        return { success: true, count: users.length };
    }

    async getAuditLogs() {
        return this.auditLogModel.find()
            .populate('performedBy', 'name email profileImage')
            .sort({ createdAt: -1 })
            .limit(100)
            .exec();
    }

    async getUserGrowth() {
        // Aggregate users by month for the last 6 months
        const sixMonthsAgo = new Date();
        sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);

        const growth = await this.userModel.aggregate([
            { $match: { createdAt: { $gte: sixMonthsAgo } } },
            {
                $group: {
                    _id: { $month: "$createdAt" },
                    count: { $sum: 1 },
                    date: { $first: "$createdAt" }
                }
            },
            { $sort: { "_id": 1 } }
        ]);

        // Format for frontend: { name: "Jan", total: 10 }
        const formattedGrowth = growth.map(item => {
            const date = new Date(item.date);
            return {
                name: date.toLocaleString('default', { month: 'short' }),
                total: item.count
            };
        });

        return formattedGrowth;
    }

    async getDashboardActivity() {
        // Fetch recent audit logs and map to activity format
        const logs = await this.auditLogModel.find()
            .populate('performedBy', 'name email profileImage')
            .sort({ createdAt: -1 })
            .limit(5)
            .exec();

        return logs.map(log => {
            // Safe navigation for performedBy
            const user = log.performedBy as any;
            const userName = user?.name || user?.email || 'System';
            const userEmail = user?.email || 'system@admin.com';
            const userImage = user?.profileImage;

            return {
                id: log._id,
                user: {
                    name: userName,
                    email: userEmail,
                    image: userImage,
                    // Generate initials if image missing
                    initials: userName.substring(0, 2).toUpperCase()
                },
                action: log.action.replace('_', ' '), // e.g. "approve_user" -> "approve user"
                details: log.details,
                timestamp: log.createdAt // Frontend can format "2m ago"
            };
        });
    }
}
