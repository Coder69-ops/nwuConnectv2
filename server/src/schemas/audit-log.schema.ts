import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Schema as MongooseSchema } from 'mongoose';

export type AuditLogDocument = AuditLog & Document;

@Schema({ timestamps: true })
export class AuditLog {
    @Prop({ required: true })
    action: string;

    @Prop({ required: true })
    details: string;

    @Prop({ type: MongooseSchema.Types.ObjectId, ref: 'User' })
    performedBy: MongooseSchema.Types.ObjectId;

    @Prop({ type: Object })
    metadata: any;

    createdAt: Date;
    updatedAt: Date;
}

export const AuditLogSchema = SchemaFactory.createForClass(AuditLog);
