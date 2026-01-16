import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ConnectController } from './connect.controller';
import { ConnectService } from './connect.service';
import { Match, MatchSchema } from '../schemas/match.schema';
import { Swipe, SwipeSchema } from '../schemas/swipe.schema';
import { NotificationModule } from '../notification/notification.module';
import { Profile, ProfileSchema } from '../schemas/profile.schema';

@Module({
    imports: [
        MongooseModule.forFeature([
            { name: Match.name, schema: MatchSchema },
            { name: Swipe.name, schema: SwipeSchema },
            { name: Profile.name, schema: ProfileSchema },
        ]),
        NotificationModule,
    ],
    controllers: [ConnectController],
    providers: [ConnectService],
})
export class ConnectModule { }
