import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as admin from 'firebase-admin';
import { Match, MatchDocument } from '../schemas/match.schema';
import { Swipe, SwipeDocument } from '../schemas/swipe.schema';
import { Profile, ProfileDocument } from '../schemas/profile.schema';
import { User, UserDocument } from '../schemas/user.schema';
import { NotificationService } from '../notification/notification.service';

@Injectable()
export class ConnectService {
    constructor(
        @InjectModel(Match.name) private matchModel: Model<MatchDocument>,
        @InjectModel(Swipe.name) private swipeModel: Model<SwipeDocument>,
        @InjectModel(Profile.name) private profileModel: Model<ProfileDocument>,
        private notificationService: NotificationService,
    ) { }

    async getCandidates(userId: string) {
        // 1. Get user profile for friends and department
        const userProfile = await this.profileModel.findOne({ userId });
        const friendIds = userProfile?.friendIds || [];
        const myDepartment = userProfile?.department || 'General';

        // 2. Get IDs of users already swiped
        const swipedDocs = await this.swipeModel.find({ swiperId: userId }).select('targetId');
        const swipedIds = swipedDocs.map(doc => doc.targetId);

        // 3. Exclusion list (Friends + Self)
        const permanentExclusions = [...friendIds, userId];

        // 4. Randomized Discovery Attempt 1: Never swiped users
        let candidates = await this.profileModel.aggregate([
            {
                $match: {
                    userId: { $nin: [...permanentExclusions, ...swipedIds] }
                }
            },
            { $sample: { size: 20 } }
        ]).exec();

        // 5. Fallback: If pool is dry, show previously "passed" users (excluding likes & friends)
        if (candidates.length < 5) {
            const likedDocs = await this.swipeModel.find({ swiperId: userId, action: 'like' }).select('targetId');
            const likedIds = likedDocs.map(doc => doc.targetId);

            const fallbackCandidates = await this.profileModel.aggregate([
                {
                    $match: {
                        userId: { $nin: [...permanentExclusions, ...likedIds] }
                    }
                },
                { $sample: { size: 20 } }
            ]).exec();

            // Merge and dedup
            const existingIds = new Set(candidates.map(c => c.userId));
            for (const f of fallbackCandidates) {
                if (!existingIds.has(f.userId)) {
                    candidates.push(f);
                }
            }
        }

        // 6. Final Polish: Shuffle and prioritize department moderately while keeping it random
        return candidates.sort((a, b) => {
            const aDeptMatch = a.department === myDepartment ? 1 : 0;
            const bDeptMatch = b.department === myDepartment ? 1 : 0;
            if (aDeptMatch !== bDeptMatch) return bDeptMatch - aDeptMatch;
            return Math.random() - 0.5; // Random within department groups
        }).slice(0, 20);
    }
    async processSwipe(swiperId: string, targetId: string, action: 'like' | 'pass') {
        // 1. Save or update the swipe (prevent duplicate key error)
        await this.swipeModel.findOneAndUpdate(
            { swiperId, targetId },
            { action },
            { upsert: true, new: true }
        ).exec();

        if (action === 'pass') {
            return { match: false };
        }

        // 2. Check for reciprocal like
        const reciprocalSwipe = await this.swipeModel.findOne({
            swiperId: targetId,
            targetId: swiperId,
            action: 'like',
        });

        if (reciprocalSwipe) {
            // 3. It's a match!
            const match = new this.matchModel({
                users: [swiperId, targetId],
                lastMessage: null,
            });
            const savedMatch = await match.save();

            // 4. Create room in Firebase RTDB
            const matchId = savedMatch._id.toString();

            // Get profiles for RTDB and Notifications
            const swiperProfile = await this.profileModel.findOne({ userId: swiperId });
            const targetProfile = await this.profileModel.findOne({ userId: targetId }).select('name photos userId');

            if (swiperProfile && targetProfile) {
                await admin.database().ref(`chats/${matchId}`).set({
                    matchId,
                    conversationId: savedMatch._id,
                    createdAt: admin.database.ServerValue.TIMESTAMP,
                    users: [
                        { ...swiperProfile.toObject(), id: swiperProfile.userId },
                        { ...targetProfile.toObject(), id: targetProfile.userId }
                    ],
                    info: {
                        active: true,
                    }
                });

                // 5. Add to each other's friendIds (Mutual Friendship)
                await this.profileModel.updateOne(
                    { userId: swiperId },
                    { $addToSet: { friendIds: targetId } }
                );
                await this.profileModel.updateOne(
                    { userId: targetId },
                    { $addToSet: { friendIds: swiperId } }
                );

                // Send Match Notification to BOTH users
                await this.notificationService.sendNotification(
                    targetId,
                    "It's a Match! 🎉",
                    `You and ${swiperProfile.name || 'someone'} liked each other!`,
                    { type: 'match', targetId: swiperId }
                );

                await this.notificationService.sendNotification(
                    swiperId,
                    "It's a Match! 🎉",
                    `You and ${targetProfile.name || 'someone'} liked each other!`,
                    { type: 'match', targetId: targetId }
                );
            }

            return {
                match: true,
                matchId,
                conversationId: savedMatch._id,
                users: (swiperProfile && targetProfile) ? [
                    { ...swiperProfile.toObject(), id: swiperProfile.userId },
                    { ...targetProfile.toObject(), id: targetProfile.userId }
                ] : []
            };
        } else {
            // Just a like (Connection Request)
            const swiperProfile = await this.profileModel.findOne({ userId: swiperId });
            await this.notificationService.sendNotification(
                targetId,
                "New Connection Request",
                `${swiperProfile?.name || 'Someone'} wants to connect with you.`,
                { type: 'request', targetId: swiperId }
            );

            return { match: false };
        }
    }
}
