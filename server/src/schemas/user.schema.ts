import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type UserDocument = User & Document;

@Schema({ timestamps: true })
export class User {
    @Prop({ required: true, unique: true })
    firebaseUid: string;

    @Prop({ required: true, unique: true })
    email: string;

    @Prop({
        required: true,
        enum: ['pending', 'approved', 'banned', 'admin'], // Added admin role
        default: 'pending',
    })
    status: string;

    @Prop({ type: Boolean, default: false })
    onboardingCompleted: boolean;

    @Prop({ type: Boolean, default: false })
    welcomeSeen: boolean;

    @Prop()
    name: string;

    @Prop()
    department: string;

    @Prop()
    bio: string;

    @Prop({ type: Object, default: {} })
    verification: {
        idCardUrl?: string;
        selfieUrl?: string;
        submitted?: boolean;
    };

    @Prop({ default: 'user' })
    role: string; // 'user' | 'admin' | 'student' | 'faculty' | 'staff'

    @Prop()
    linkedinUrl: string;

    @Prop()
    facebookUrl: string;

    @Prop()
    notificationToken: string;

    @Prop()
    profileImage: string;
}

export const UserSchema = SchemaFactory.createForClass(User);
