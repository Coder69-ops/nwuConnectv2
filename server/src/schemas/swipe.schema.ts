import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type SwipeDocument = Swipe & Document;

@Schema({ timestamps: true })
export class Swipe {
    @Prop({ required: true })
    swiperId: string; // The user who swiped

    @Prop({ required: true })
    targetId: string; // The user being swiped on

    @Prop({ required: true, enum: ['like', 'pass'] })
    action: string;
}

// Composite index to ensure a user can only swipe once on another user
export const SwipeSchema = SchemaFactory.createForClass(Swipe);
SwipeSchema.index({ swiperId: 1, targetId: 1 }, { unique: true });
