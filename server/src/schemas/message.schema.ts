import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type MessageDocument = Message & Document;

@Schema({ timestamps: true })
export class Message {
    @Prop({ required: true })
    conversationId: string;

    @Prop({ required: true })
    senderId: string;

    @Prop({ required: true })
    content: string;

    @Prop({ default: 'text' })
    type: string;

    @Prop()
    imageUrl?: string;

    @Prop({ default: 'sent' })
    status: string; // sent, delivered, seen

    @Prop({ default: false })
    read: boolean;
}

export const MessageSchema = SchemaFactory.createForClass(Message);
