import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type ProfileDocument = Profile & Document;

@Schema({ timestamps: true })
export class Profile {
    @Prop({ required: true, unique: true })
    userId: string; // References User.firebaseUid or _id

    @Prop({ required: true })
    name: string;

    @Prop()
    bio: string;

    @Prop([String])
    interests: string[];

    @Prop([String])
    photos: string[];

    @Prop()
    coverPhoto: string; // URL for the cover photo

    @Prop({ type: Object })
    location: {
        lat: number;
        lng: number;
        address?: string;
    };

    @Prop({ required: true, enum: ['CSE', 'EEE', 'ECE', 'Civil Engineering', 'Business Administration', 'Law', 'English', 'Economics', 'Sociology', 'Development Studies', 'Public Health'] })
    department: string;

    @Prop({ type: [String], default: [] })
    friendIds: string[];

    @Prop()
    studentId: string;

    @Prop()
    year: string; // e.g. "1.1", "4.2"

    @Prop()
    section: string; // e.g. "A", "B"

    @Prop()
    linkedinUrl: string;

    @Prop()
    facebookUrl: string;

    @Prop({ default: false })
    isOnline: boolean;

    @Prop({ default: Date.now })
    lastSeen: Date;

    @Prop({
        type: Object, default: {
            email: 'public',
            studentId: 'public',
            year: 'public',
            section: 'public',
            location: 'public',
            interests: 'public',
            department: 'public',
            bio: 'public'
        }
    })
    privacy: {
        email?: string;
        studentId?: string;
        year?: string;
        section?: string;
        location?: string;
        interests?: string;
        department?: string;
        bio?: string;
    };
}

export const ProfileSchema = SchemaFactory.createForClass(Profile);

