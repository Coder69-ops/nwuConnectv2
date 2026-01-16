
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type PostDocument = Post & Document;

@Schema({ _id: true })
export class Reply {
    @Prop({ required: true })
    userId: string;

    @Prop({ required: true })
    text: string;

    @Prop({ default: Date.now })
    createdAt: Date;
}

@Schema({ _id: true })
export class Comment {
    @Prop({ required: true })
    userId: string;

    @Prop({ required: true })
    text: string;

    @Prop({ default: Date.now })
    createdAt: Date;

    @Prop({ type: [SchemaFactory.createForClass(Reply)], default: [] })
    replies: Reply[];
}

@Schema({ timestamps: true })
export class Post {
    @Prop({ required: true })
    userId: string; // The author's Firebase UID

    @Prop({ default: '' })
    content: string;

    @Prop([String])
    imageUrls: string[];

    @Prop({ required: true, enum: ['public', 'friends', 'department'] })
    visibility: string;

    @Prop({ required: true })
    authorDepartment: string; // Snapshot at creation

    @Prop({ type: [String], default: [] })
    likes: string[]; // List of userIds who liked

    @Prop({ type: [SchemaFactory.createForClass(Comment)], default: [] })
    comments: Comment[];

    @Prop({ default: false })
    isArchived: boolean;

    @Prop({
        type: [{
            content: String,
            editedAt: Date
        }],
        default: []
    })
    editHistory: { content: string; editedAt: Date }[];
}

export const PostSchema = SchemaFactory.createForClass(Post);

// Index for timeline queries
PostSchema.index({ createdAt: -1 });
