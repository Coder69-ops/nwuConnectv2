import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { UserController } from './user.controller';
import { UserService } from './user.service';
import { User, UserSchema } from '../schemas/user.schema';
import { Post, PostSchema } from '../schemas/post.schema';
import { Profile, ProfileSchema } from '../schemas/profile.schema';
import { Swipe, SwipeSchema } from '../schemas/swipe.schema';

@Module({
    imports: [
        MongooseModule.forFeature([
            { name: User.name, schema: UserSchema },
            { name: Profile.name, schema: ProfileSchema },
            { name: Post.name, schema: PostSchema },
            { name: Swipe.name, schema: SwipeSchema },
        ]),
    ],
    controllers: [UserController],
    providers: [UserService],
    exports: [UserService],
})
export class UserModule { }
