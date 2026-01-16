
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Profile, ProfileDocument } from '../schemas/profile.schema';

@Injectable()
export class ProfileService {
    constructor(
        @InjectModel(Profile.name) private profileModel: Model<ProfileDocument>,
    ) { }

    async upsertProfile(userId: string, data: { name: string; bio: string; department: string; interests?: string[] }) {
        return this.profileModel.findOneAndUpdate(
            { userId },
            { userId, ...data },
            { upsert: true, new: true, setDefaultsOnInsert: true },
        );
    }

    async getProfile(userId: string) {
        return this.profileModel.findOne({ userId });
    }
}
