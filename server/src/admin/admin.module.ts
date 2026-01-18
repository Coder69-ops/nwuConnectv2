import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { User, UserSchema } from '../schemas/user.schema';
import { Report, ReportSchema } from '../schemas/report.schema';
import { AuditLog, AuditLogSchema } from '../schemas/audit-log.schema';
import { Notification, NotificationSchema } from '../schemas/notification.schema';

@Module({
    imports: [
        MongooseModule.forFeature([
            { name: User.name, schema: UserSchema },
            { name: Report.name, schema: ReportSchema },
            { name: AuditLog.name, schema: AuditLogSchema },
            { name: Notification.name, schema: NotificationSchema }
        ]),
    ],
    controllers: [AdminController],
    providers: [AdminService],
})
export class AdminModule { }
