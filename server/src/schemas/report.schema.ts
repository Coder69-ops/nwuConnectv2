import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Schema as MongooseSchema } from 'mongoose';

export type ReportDocument = Report & Document;

@Schema({ timestamps: true })
export class Report {
    @Prop({ type: MongooseSchema.Types.ObjectId, ref: 'User', required: true })
    reporter: MongooseSchema.Types.ObjectId;

    @Prop({ type: MongooseSchema.Types.ObjectId, ref: 'User', required: true })
    reportedUser: MongooseSchema.Types.ObjectId;

    @Prop({ required: true })
    reason: string;

    @Prop({ required: true, enum: ['open', 'resolved', 'dismissed'], default: 'open' })
    status: string;

    @Prop()
    description: string;
}

export const ReportSchema = SchemaFactory.createForClass(Report);
