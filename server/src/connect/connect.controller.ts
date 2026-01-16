import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { ConnectService } from './connect.service';

@Controller('connect')
@UseGuards(FirebaseAuthGuard)
export class ConnectController {
    constructor(private readonly connectService: ConnectService) { }

    @Get('candidates')
    async getCandidates(@Req() req: any) {
        return this.connectService.getCandidates(req.user.uid);
    }

    @Post('swipe')
    async swipe(@Req() req: any, @Body() body: { targetId: string; action: 'like' | 'pass' }) {
        const swiperId = req.user.uid; // From FirebaseAuthGuard
        return this.connectService.processSwipe(swiperId, body.targetId, body.action);
    }
}
