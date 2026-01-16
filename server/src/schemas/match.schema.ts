import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type MatchDocument = Match & Document;

@Schema({ timestamps: true })
export class Match {
    @Prop({ required: true, type: [String] })
    users: string[]; // Array of 2 ObjectIds or firebaseUids

    @Prop()
    lastMessage: string;

    @Prop()
    lastMessageTime: Date;
}

export const MatchSchema = SchemaFactory.createForClass(Match);
