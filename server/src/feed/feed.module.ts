
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { FeedController } from './feed.controller';
import { FeedService } from './feed.service';
import { Post, PostSchema } from '../schemas/post.schema';
import { Profile, ProfileSchema } from '../schemas/profile.schema';

@Module({
    imports: [
        MongooseModule.forFeature([
            { name: Post.name, schema: PostSchema },
            { name: Profile.name, schema: ProfileSchema },
        ]),
    ],
    controllers: [FeedController],
    providers: [FeedService],
})
export class FeedModule { }
