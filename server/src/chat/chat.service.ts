import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Message, MessageDocument } from '../schemas/message.schema';
import { Conversation, ConversationDocument } from '../schemas/conversation.schema';
import { Profile, ProfileDocument } from '../schemas/profile.schema';
import * as admin from 'firebase-admin';
import { NotificationService } from '../notification/notification.service';

@Injectable()
export class ChatService {
    constructor(
        @InjectModel(Message.name) private messageModel: Model<MessageDocument>,
        @InjectModel(Conversation.name) private conversationModel: Model<ConversationDocument>,
        @InjectModel(Profile.name) private profileModel: Model<ProfileDocument>,
        private notificationService: NotificationService,
    ) { }

    async getOrCreateConversation(initiatorId: string, targetId: string) {
        let conversation = await this.conversationModel.findOne({
            participants: { $all: [initiatorId, targetId], $size: 2 }
        });

        if (!conversation) {
            conversation = new this.conversationModel({
                participants: [initiatorId, targetId],
                lastMessage: '',
                lastMessageAt: new Date(),
            });
            await conversation.save();
        }
        return conversation;
    }

    async sendMessage(senderId: string, targetId: string, content: string, type = 'text', imageUrl?: string) {
        // 1. Find or Create Conversation
        let conversation = await this.conversationModel.findOne({
            participants: { $all: [senderId, targetId], $size: 2 }
        });

        const lastText = type === 'image' ? 'Sent a photo' : content;

        if (!conversation) {
            conversation = new this.conversationModel({
                participants: [senderId, targetId],
                lastMessage: lastText,
                lastMessageAt: new Date(),
            });
        } else {
            conversation.lastMessage = lastText;
            conversation.lastMessageAt = new Date();
        }
        await conversation.save();

        // 2. Create Message
        const message = new this.messageModel({
            conversationId: conversation._id,
            senderId,
            content,
            type,
            imageUrl,
            status: 'sent',
        });
        const savedMessage = await message.save();

        // 3. Push to Firebase RTDB for Real-time sync
        const matchId = conversation._id.toString();
        await admin.database().ref(`chats/${matchId}/messages/${savedMessage._id}`).set({
            senderId,
            content,
            type,
            imageUrl,
            status: 'sent',
            createdAt: admin.database.ServerValue.TIMESTAMP,
        });

        // 4. Send Notification
        const senderProfile = await this.profileModel.findOne({ userId: senderId });
        const senderName = senderProfile ? senderProfile.name : 'Someone';
        const notificationBody = type === 'image' ? 'Sent a photo' : content;

        await this.notificationService.sendNotification(
            targetId,
            senderName,
            notificationBody,
            { type: 'chat', conversationId: conversation._id.toString() }
        );

        return savedMessage;
    }

    async markAsRead(conversationId: string, userId: string) {
        // Update MongoDB
        await this.messageModel.updateMany(
            { conversationId, senderId: { $ne: userId }, read: false },
            { $set: { read: true, status: 'seen' } }
        );

        // Notify RTDB by updating existing messages status (simplified approach)
        // In a full system, we might push a 'seen_until' pointer, but for this app, 
        // we'll update the 'status' of messages in the chat node.
        const ref = admin.database().ref(`chats/${conversationId}/messages`);
        const snapshot = await ref.once('value');
        const messages = snapshot.val();

        if (messages) {
            const updates: any = {};
            Object.keys(messages).forEach(key => {
                if (messages[key].senderId !== userId && messages[key].status !== 'seen') {
                    updates[`${key}/status`] = 'seen';
                }
            });
            if (Object.keys(updates).length > 0) {
                await ref.update(updates);
            }
        }

        return { success: true };
    }

    async getConversations(userId: string) {
        const conversations = await this.conversationModel.find({
            participants: userId
        }).sort({ lastMessageAt: -1 }).lean();

        // Enrich with other participant's details
        const otherUserIds = conversations.map(c =>
            c.participants.find(p => p !== userId)
        ).filter(id => !!id) as string[];

        const validIds = [...new Set(otherUserIds)];
        const profiles = await this.profileModel.find({ userId: { $in: validIds } }).lean();
        const profileMap = new Map(profiles.map(p => [p.userId, p]));

        return conversations.map(c => {
            const otherId = c.participants.find(p => p !== userId);
            const profile = otherId ? profileMap.get(otherId) : null;
            return {
                id: c._id,
                lastMessage: c.lastMessage,
                lastMessageAt: c.lastMessageAt,
                otherUser: {
                    id: otherId,
                    name: profile ? profile.name : 'Unknown User',
                    photo: (profile?.photos && profile.photos.length > 0) ? profile.photos[0] : '',
                }
            };
        });
    }

    async getMessages(conversationId: string, limit = 50) {
        return this.messageModel.find({ conversationId })
            .sort({ createdAt: 1 }) // Oldest first for chat history, or -1 for pagination
            .limit(limit)
            .exec();
    }
}
