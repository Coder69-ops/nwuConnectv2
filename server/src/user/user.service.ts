import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User, UserDocument } from '../schemas/user.schema';
import { Profile, ProfileDocument } from '../schemas/profile.schema';
import { Post, PostDocument } from '../schemas/post.schema';
import { Swipe, SwipeDocument } from '../schemas/swipe.schema';

@Injectable()
export class UserService {
    constructor(
        @InjectModel(User.name) private userModel: Model<UserDocument>,
        @InjectModel(Profile.name) private profileModel: Model<ProfileDocument>,
        @InjectModel(Post.name) private postModel: Model<PostDocument>,
        @InjectModel(Swipe.name) private swipeModel: Model<SwipeDocument>,
    ) { }

    async findByUid(firebaseUid: string) {
        return this.userModel.findOne({ firebaseUid });
    }

    async findById(id: string) {
        return this.userModel.findById(id);
    }

    async getPublicProfile(targetUserId: string, requestingUserId?: string) {
        const user = await this.userModel.findOne({ firebaseUid: targetUserId }).lean() as any;
        if (!user) throw new NotFoundException('User not found');

        const profile = await this.profileModel.findOne({ userId: targetUserId }).lean();

        // Count posts and friends
        const postsCount = await this.postModel.countDocuments({ userId: targetUserId });
        const friendsCount = profile?.friendIds?.length || 0;

        // Determine relationship
        const isSelf = requestingUserId === targetUserId;
        const isFriend = requestingUserId && profile?.friendIds?.includes(requestingUserId);

        // Check connection status (pending request)
        let connectionStatus = 'none'; // 'none', 'pending', 'friend'
        if (isFriend) {
            connectionStatus = 'friend';
        } else if (requestingUserId) {
            const pendingSwipe = await this.swipeModel.findOne({
                swiperId: requestingUserId,
                targetId: targetUserId,
                action: 'like'
            });
            if (pendingSwipe) {
                connectionStatus = 'pending';
            }
        }

        // Helper to check if field should be visible
        const canView = (fieldPrivacy: string) => {
            if (isSelf) return true; // Owner can always see their own data
            if (fieldPrivacy === 'public') return true;
            if (fieldPrivacy === 'friends' && isFriend) return true;
            return false; // 'private' or not authorized
        };

        const privacy = profile?.privacy || {};

        const baseProfile = {
            userId: user.firebaseUid,
            name: profile?.name || 'User',
            photo: (profile?.photos && profile.photos.length > 0) ? profile.photos[0] : '',
            coverPhoto: profile?.coverPhoto || '',
            postsCount,
            friendsCount,
            isVerified: true,
            status: user.status,
        };

        // Conditionally add fields based on privacy
        return {
            ...baseProfile,
            isFriend,
            isSelf,
            connectionStatus,
            ...(canView(privacy.bio || 'public') && { bio: profile?.bio || '' }),
            ...(canView(privacy.department || 'public') && { department: profile?.department || '' }),
            ...(canView(privacy.studentId || 'public') && { studentId: profile?.studentId || '' }),
            ...(canView(privacy.year || 'public') && { year: profile?.year || '' }),
            ...(canView(privacy.section || 'public') && { section: profile?.section || '' }),
            ...(canView(privacy.email || 'public') && { email: user.email }),
            ...(canView(privacy.location || 'public') && { location: profile?.location?.address || '' }),
            ...(canView(privacy.interests || 'public') && { interests: profile?.interests || [] }),
            linkedinUrl: profile?.linkedinUrl || '',
            facebookUrl: profile?.facebookUrl || '',
            joinedAt: user.createdAt,
        };
    }

    async getMe(firebaseUid: string) {
        const user = await this.findByUid(firebaseUid);
        if (!user) throw new NotFoundException('User not found');

        // Enrich with Profile Data
        const profile = await this.profileModel.findOne({ userId: firebaseUid }).lean();

        return {
            ...user.toObject(),
            name: profile?.name || user.name, // Prefer profile name if exists
            photoUrl: (profile?.photos && profile.photos.length > 0) ? profile.photos[0] : '',
            department: profile?.department || user.department,
            bio: profile?.bio || '',
            studentId: profile?.studentId || '',
            year: profile?.year || '',
            section: profile?.section || '',
            coverPhoto: profile?.coverPhoto || '',
            friendIds: profile?.friendIds || [],
        };
    }

    async syncUser(firebaseUid: string, email: string) {
        let user = await this.userModel.findOne({ firebaseUid });

        if (!user) {
            user = new this.userModel({
                firebaseUid,
                email,
                status: 'pending',
                onboardingCompleted: false,
                role: 'user',
                verification: { submitted: false }
            });
            await user.save();
        } else if (user.email !== email) {
            user.email = email;
            await user.save();
        }
        return user;
    }

    async updateStatus(id: string, status: string) {
        return this.userModel.findByIdAndUpdate(id, { status }, { new: true });
    }

    async markWelcomeSeen(firebaseUid: string) {
        return this.userModel.findOneAndUpdate(
            { firebaseUid },
            { welcomeSeen: true },
            { new: true }
        );
    }

    async updateProfile(firebaseUid: string, data: {
        name: string;
        department: string;
        bio?: string;
        studentId?: string;
        year?: string;
        section?: string;
        photo?: string;
        coverPhoto?: string;
        linkedinUrl?: string;
        facebookUrl?: string;
        privacy?: any
    }) {
        console.log('UpdateProfile Data:', data); // DEBUG LOG
        // 1. Update User Document
        const user = await this.userModel.findOneAndUpdate(
            { firebaseUid },
            {
                name: data.name,
                department: data.department,
                onboardingCompleted: true
            },
            { new: true }
        );

        if (!user) throw new NotFoundException('User not found');

        // 2. Upsert Profile Document
        const profileUpdate: any = {
            userId: firebaseUid,
            name: data.name,
            department: data.department,
            bio: data.bio || '',
            studentId: data.studentId || '',
            year: data.year || '',
            section: data.section || '',
            linkedinUrl: data.linkedinUrl || '',
            facebookUrl: data.facebookUrl || '',
        };

        // Handle photo update
        if (data.photo) {
            const profile = await this.profileModel.findOne({ userId: firebaseUid });
            profileUpdate.photos = profile?.photos || [];
            if (!profileUpdate.photos.includes(data.photo)) {
                profileUpdate.photos = [data.photo, ...profileUpdate.photos.slice(0, 4)]; // Keep max 5 photos
            }
        }

        if (data.coverPhoto) {
            console.log('Updating Cover Photo to:', data.coverPhoto); // DEBUG LOG
            profileUpdate.coverPhoto = data.coverPhoto;
        }

        if (data.privacy) {
            profileUpdate.privacy = data.privacy;
        }

        const updatedProfile = await this.profileModel.findOneAndUpdate(
            { userId: firebaseUid },
            { $set: profileUpdate },
            { upsert: true, new: true }
        );
        console.log('Updated Profile Document:', updatedProfile); // DEBUG LOG

        return user;
    }

    async updateVerification(firebaseUid: string, data: { idCardUrl: string; selfieUrl: string; submitted: boolean }) {
        return this.userModel.findOneAndUpdate(
            { firebaseUid },
            {
                'verification.idCardUrl': data.idCardUrl,
                'verification.selfieUrl': data.selfieUrl,
                'verification.submitted': data.submitted
            },
            { new: true }
        );
    }

    async updatePresence(firebaseUid: string, isOnline: boolean) {
        return this.userModel.findOneAndUpdate(
            { firebaseUid },
            { isOnline, lastSeen: new Date() },
            { new: true }
        );
    }

    async updateDeviceToken(firebaseUid: string, fcmToken: string) {
        return this.userModel.findOneAndUpdate(
            { firebaseUid },
            { notificationToken: fcmToken },
            { new: true }
        );
    }
}
