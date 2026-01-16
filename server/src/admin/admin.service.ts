import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User, UserDocument } from '../schemas/user.schema';
import { Report, ReportDocument } from '../schemas/report.schema';

@Injectable()
export class AdminService {
    constructor(
        @InjectModel(User.name) private userModel: Model<UserDocument>,
        @InjectModel(Report.name) private reportModel: Model<ReportDocument>,
    ) { }

    async getStats() {
        const totalUsers = await this.userModel.countDocuments();
        const pendingVerifications = await this.userModel.countDocuments({
            status: 'pending',
            'verification.submitted': true
        });
        const activeReports = await this.reportModel.countDocuments({ status: 'open' });
        const onlineNow = 0; // Placeholder

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
        return this.userModel.findByIdAndUpdate(id, { status: 'approved' }, { new: true });
    }

    async rejectUser(id: string, reason: string) {
        return this.userModel.findByIdAndUpdate(id, {
            'verification.submitted': false,
        }, { new: true });
    }

    async banUser(id: string) {
        return this.userModel.findByIdAndUpdate(id, { status: 'banned' }, { new: true });
    }

    async unbanUser(id: string) {
        return this.userModel.findByIdAndUpdate(id, { status: 'approved' }, { new: true });
    }

    // --- Real Reports ---
    async getReports() {
        return this.reportModel.find()
            .populate('reporter', 'name email profileImage')
            .populate('reportedUser', 'name email profileImage')
            .sort({ createdAt: -1 })
            .exec();
    }

    async resolveReport(id: string) {
        return this.reportModel.findByIdAndUpdate(id, { status: 'resolved' }, { new: true });
    }

    async dismissReport(id: string) {
        return this.reportModel.findByIdAndUpdate(id, { status: 'dismissed' }, { new: true });
    }

    // --- Mock Broadcasts ---
    async sendBroadcast(title: string, message: string) {
        console.log(`[BROADCAST] ${title}: ${message}`);
        return { success: true, sentTo: 'all' };
    }
}
