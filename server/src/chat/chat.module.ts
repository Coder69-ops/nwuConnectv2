import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ChatController } from './chat.controller';
import { ChatService } from './chat.service';
import { Message, MessageSchema } from '../schemas/message.schema';
import { Conversation, ConversationSchema } from '../schemas/conversation.schema';
import { Profile, ProfileSchema } from '../schemas/profile.schema';
import { NotificationModule } from '../notification/notification.module';

@Module({
    imports: [
        MongooseModule.forFeature([
            { name: Message.name, schema: MessageSchema },
            { name: Conversation.name, schema: ConversationSchema },
            { name: Profile.name, schema: ProfileSchema },
        ]),
        NotificationModule,
    ],
    controllers: [ChatController],
    providers: [ChatService],
})
export class ChatModule { }
