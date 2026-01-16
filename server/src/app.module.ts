
import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { ConnectModule } from './connect/connect.module';
import { UploadModule } from './upload/upload.module';
import { FeedModule } from './feed/feed.module';
import { ProfileModule } from './profile/profile.module';
import { ChatModule } from './chat/chat.module';
import { User, UserSchema } from './schemas/user.schema';
import { Profile, ProfileSchema } from './schemas/profile.schema';

import { UserModule } from './user/user.module';
import { AdminModule } from './admin/admin.module';
import { NotificationModule } from './notification/notification.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    MongooseModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => ({
        uri: configService.get<string>('MONGO_URI'),
        serverSelectionTimeoutMS: 5000, // Timeout after 5s instead of 30s
        socketTimeoutMS: 45000, // Close sockets after 45s of inactivity
        maxPoolSize: 10, // Maintain up to 10 socket connections
      }),
      inject: [ConfigService],
    }),
    UserModule,
    AdminModule,
    NotificationModule,
    ConnectModule,
    UploadModule,
    FeedModule,
    ProfileModule,
    ChatModule,
    MongooseModule.forFeature([
      { name: Profile.name, schema: ProfileSchema },
    ]),
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule { }
