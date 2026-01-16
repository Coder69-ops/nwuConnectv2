import { Injectable, Logger } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User, UserDocument } from '../schemas/user.schema';
import { Notification, NotificationDocument } from '../schemas/notification.schema';

@Injectable()
export class NotificationService {
    private readonly logger = new Logger(NotificationService.name);

    constructor(
        @InjectModel(User.name) private userModel: Model<UserDocument>,
        @InjectModel(Notification.name) private notificationModel: Model<NotificationDocument>,
    ) { }

    async sendNotification(userId: string, title: string, body: string, data?: Record<string, string>) {
        // 1. Save to Database
        try {
            await this.notificationModel.create({
                userId,
                title,
                body,
                data,
                isRead: false,
            });
        } catch (error) {
            this.logger.error(`Error saving notification for ${userId}:`, error);
        }

        // 2. Send Push Notification via Firebase
        try {
            const user = await this.userModel.findOne({ firebaseUid: userId });
            if (!user || !user.notificationToken) {
                this.logger.warn(`User ${userId} has no notification token`);
                return;
            }

            const message: admin.messaging.Message = {
                token: user.notificationToken,
                notification: {
                    title,
                    body,
                },
                data: data || {},
                android: {
                    priority: 'high',
                    notification: {
                        channelId: 'high_importance_channel',
                    }
                },
                apns: {
                    payload: {
                        aps: {
                            sound: 'default',
                        },
                    },
                },
            };

            const response = await admin.messaging().send(message);
            this.logger.log(`Successfully sent message: ${response}`);
        } catch (error) {
            this.logger.error(`Error sending notification to ${userId}:`, error);
        }
    }

    async getUserNotifications(userId: string) {
        return this.notificationModel.find({ userId }).sort({ createdAt: -1 }).limit(50);
    }

    async markAsRead(notificationId: string) {
        return this.notificationModel.findByIdAndUpdate(notificationId, { isRead: true }, { new: true });
    }

    async markAllAsRead(userId: string) {
        return this.notificationModel.updateMany({ userId, isRead: false }, { isRead: true });
    }
}
