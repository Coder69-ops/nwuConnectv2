import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { User, UserSchema } from '../schemas/user.schema';
import { Report, ReportSchema } from '../schemas/report.schema';

@Module({
    imports: [
        MongooseModule.forFeature([
            { name: User.name, schema: UserSchema },
            { name: Report.name, schema: ReportSchema }
        ]),
    ],
    controllers: [AdminController],
    providers: [AdminService],
})
export class AdminModule { }
