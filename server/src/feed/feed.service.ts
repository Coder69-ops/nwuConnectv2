
import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Post, PostDocument } from '../schemas/post.schema';
import { Profile, ProfileDocument } from '../schemas/profile.schema';

@Injectable()
export class FeedService {
    constructor(
        @InjectModel(Post.name) private postModel: Model<PostDocument>,
        @InjectModel(Profile.name) private profileModel: Model<ProfileDocument>,
    ) { }

    async createPost(userId: string, data: { content: string; imageUrls: string[]; visibility: string }) {
        // 1. Get author's profile for department snapshot
        const authorProfile = await this.profileModel.findOne({ userId });

        // Fallback to 'General' if profile not found (e.g. legacy user or skip onboarding)
        const department = authorProfile?.department || 'General';

        const post = new this.postModel({
            userId,
            ...data,
            authorDepartment: department,
        });
        return post.save();
    }

    async getFeed(userId: string, limit = 20, offset = 0) {
        // 1. Get requesting user's profile to know their dept and friends
        const userProfile = await this.profileModel.findOne({ userId });

        // Graceful Fallback: If no profile, assume "General" and no friends.
        const department = userProfile?.department || 'General';
        const friendIds = userProfile?.friendIds || [];

        // 2. Query Logic
        // 2. Query Logic (Discovery Focus: Randomized Sample)
        const posts = await this.postModel.aggregate([
            {
                $match: {
                    isArchived: { $ne: true },
                    $or: [
                        { visibility: 'public' },
                        { visibility: 'department', authorDepartment: department },
                        { visibility: 'friends', userId: { $in: friendIds } },
                        { userId: userId }
                    ]
                }
            },
            { $sample: { size: limit } } // Fetch random sample
        ]).exec();

        // 3. Manual Join
        const userIds = [...new Set(posts.map(p => p.userId))];
        const profiles = await this.profileModel.find({ userId: { $in: userIds } }).lean();
        const profileMap = new Map(profiles.map(p => [p.userId, p]));

        // 4. Attach Author Details
        return posts.map(post => {
            const profile = profileMap.get(post.userId);
            return {
                ...post,
                authorName: profile ? profile.name : 'Unknown User',
                authorPhoto: (profile?.photos && profile.photos.length > 0) ? profile.photos[0] : '',
            };
        });
    }

    async getUserPosts(targetUserId: string, limit = 20, offset = 0) {
        const posts = await this.postModel.find({
            userId: targetUserId,
            isArchived: { $ne: true }
        })
            .sort({ createdAt: -1 })
            .skip(offset)
            .limit(limit)
            .lean()
            .exec();

        // Join Profile
        const userIds = [...new Set(posts.map(p => p.userId))];
        const profiles = await this.profileModel.find({ userId: { $in: userIds } }).lean();
        const profileMap = new Map(profiles.map(p => [p.userId, p]));

        return posts.map(post => {
            const profile = profileMap.get(post.userId);
            return {
                ...post,
                authorName: profile ? profile.name : 'Unknown User',
                authorPhoto: (profile?.photos && profile.photos.length > 0) ? profile.photos[0] : '',
            };
        });
    }

    async toggleLike(userId: string, postId: string) {
        const post = await this.postModel.findById(postId);
        if (!post) throw new NotFoundException('Post not found');

        const index = post.likes.indexOf(userId);
        if (index > -1) {
            post.likes.splice(index, 1);
        } else {
            post.likes.push(userId);
        }
        return post.save();
    }

    async addComment(userId: string, postId: string, text: string) {
        return this.postModel.findByIdAndUpdate(
            postId,
            {
                $push: {
                    comments: {
                        userId,
                        text,
                        createdAt: new Date(),
                    }
                }
            },
            { new: true }
        );
    }

    async replyToComment(userId: string, postId: string, commentId: string, text: string) {
        console.log(`Replying to post ${postId}, comment ${commentId}, text: ${text}`);
        const updatedPost = await this.postModel.findOneAndUpdate(
            { _id: postId, 'comments._id': commentId },
            {
                $push: {
                    'comments.$.replies': {
                        userId,
                        text,
                        createdAt: new Date(),
                    }
                }
            },
            { new: true }
        );
        if (!updatedPost) console.log('Post or Comment not found for reply!');
        return updatedPost;
    }

    async getComments(postId: string) {
        const post = await this.postModel.findById(postId).lean();
        if (!post) throw new NotFoundException('Post not found');

        const comments = post.comments || [];
        const userIds = new Set<string>();
        comments.forEach((c: any) => {
            userIds.add(c.userId);
            if (c.replies) {
                c.replies.forEach((r: any) => userIds.add(r.userId));
            }
        });

        const profiles = await this.profileModel.find({ userId: { $in: [...userIds] } }).lean();
        const profileMap = new Map(profiles.map(p => [p.userId, p]));

        const attachProfile = (userId: string) => {
            const profile = profileMap.get(userId);
            return {
                authorName: profile ? profile.name : 'Unknown',
                authorPhoto: (profile?.photos && profile.photos.length > 0) ? profile.photos[0] : ''
            };
        };

        return comments.map((c: any) => {
            const commentAuthor = attachProfile(c.userId);
            const replies = (c.replies || []).map((r: any) => ({
                ...r,
                ...attachProfile(r.userId)
            })).sort((a: any, b: any) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime());

            return {
                ...c,
                ...commentAuthor,
                replies
            };
        }).sort((a: any, b: any) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
    }

    // --- Post Management Features ---

    async deletePost(userId: string, postId: string) {
        const post = await this.postModel.findOne({ _id: postId, userId });
        if (!post) throw new NotFoundException('Post not found or unauthorized');
        await this.postModel.deleteOne({ _id: postId });
        return { success: true };
    }

    async archivePost(userId: string, postId: string) {
        const post = await this.postModel.findOne({ _id: postId, userId });
        if (!post) throw new NotFoundException('Post not found or unauthorized');

        post.isArchived = !post.isArchived; // Toggle
        return post.save();
    }

    async editPost(userId: string, postId: string, newContent: string) {
        const post = await this.postModel.findOne({ _id: postId, userId });
        if (!post) throw new NotFoundException('Post not found or unauthorized');

        // Push current content to history
        post.editHistory.push({
            content: post.content,
            editedAt: new Date(),
        });

        post.content = newContent;
        return post.save();
    }

    async getPostHistory(postId: string) {
        const post = await this.postModel.findById(postId).select('editHistory').lean();
        if (!post) throw new NotFoundException('Post not found');
        return post.editHistory || [];
    }
}
