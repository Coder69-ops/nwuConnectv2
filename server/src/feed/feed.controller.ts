
import { Body, Controller, Get, Param, Post, Query, Req, UseGuards } from '@nestjs/common';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { FeedService } from './feed.service';

@Controller('feed')
@UseGuards(FirebaseAuthGuard)
export class FeedController {
    constructor(private readonly feedService: FeedService) { }

    @Post('create')
    async create(@Req() req: any, @Body() body: { content: string; imageUrls: string[]; visibility: string }) {
        console.log(`POST /feed/create hit by ${req.user.uid}`);
        return this.feedService.createPost(req.user.uid, body);
    }

    @Get('ping')
    ping() {
        return { status: 'ok' };
    }

    @Get('/')
    async getFeed(@Req() req: any, @Query('limit') limit: number, @Query('offset') offset: number) {
        console.log('GET /feed hit');
        return this.feedService.getFeed(req.user.uid, limit, offset);
    }
    @Get('/user/:userId')
    async getUserPosts(@Req() req: any, @Param('userId') userId: string, @Query('limit') limit: number, @Query('offset') offset: number) {
        console.log(`GET /feed/user/${userId} hit`);
        return this.feedService.getUserPosts(userId, limit, offset);
    }
    @Post('/:postId/like')
    async toggleLike(@Req() req: any, @Param('postId') postId: string) {
        return this.feedService.toggleLike(req.user.uid, postId);
    }

    @Post('/:postId/comment')
    async addComment(@Req() req: any, @Param('postId') postId: string, @Body() body: { text: string }) {
        return this.feedService.addComment(req.user.uid, postId, body.text);
    }

    @Post('/:postId/comment/:commentId/reply')
    async replyToComment(
        @Req() req: any,
        @Param('postId') postId: string,
        @Param('commentId') commentId: string,
        @Body() body: { text: string }
    ) {
        return this.feedService.replyToComment(req.user.uid, postId, commentId, body.text);
    }

    @Get('/:postId/comments')
    async getComments(@Param('postId') postId: string) {
        return this.feedService.getComments(postId);
    }

    // --- Post Management ---

    @Post('/:postId/delete') // Using POST or DELETE depending on what flutter supports easier, standard is DELETE
    async deletePost(@Req() req: any, @Param('postId') postId: string) {
        return this.feedService.deletePost(req.user.uid, postId);
    }

    @Post('/:postId/archive')
    async archivePost(@Req() req: any, @Param('postId') postId: string) {
        return this.feedService.archivePost(req.user.uid, postId);
    }

    @Post('/:postId/edit')
    async editPost(@Req() req: any, @Param('postId') postId: string, @Body() body: { content: string }) {
        return this.feedService.editPost(req.user.uid, postId, body.content);
    }

    @Get('/:postId/history')
    async getPostHistory(@Param('postId') postId: string) {
        return this.feedService.getPostHistory(postId);
    }
}
