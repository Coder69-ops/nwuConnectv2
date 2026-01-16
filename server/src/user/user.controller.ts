import { Body, Controller, Get, Param, Patch, Post, Put, Query, Req, UploadedFile, UseGuards, UseInterceptors } from '@nestjs/common';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { UserService } from './user.service';

@Controller('user')
@UseGuards(FirebaseAuthGuard)
export class UserController {
    constructor(private readonly userService: UserService) { }

    @Get('me')
    async getMe(@Req() req: any) {
        return this.userService.getMe(req.user.uid);
    }

    @Get('/:userId')
    async getPublicProfile(@Param('userId') userId: string, @Req() req: any) {
        const requestingUserId = req.user?.uid; // May be undefined if not authenticated
        return this.userService.getPublicProfile(userId, requestingUserId);
    }

    @Post('sync')
    async syncUser(@Req() req: any, @Body() body: { email: string }) {
        return this.userService.syncUser(req.user.uid, body.email);
    }

    @Patch('welcome')
    async markWelcomeSeen(@Req() req: any) {
        return this.userService.markWelcomeSeen(req.user.uid);
    }

    @Patch('profile')
    async updateProfile(@Req() req: any, @Body() body: {
        name: string;
        department: string;
        bio?: string;
        studentId?: string;
        year?: string;
        section?: string;
        photo?: string;
        coverPhoto?: string;
        linkedinUrl?: string;
        facebookUrl?: string;
        privacy?: any;
    }) {
        return this.userService.updateProfile(req.user.uid, body);
    }
    @Patch('verification')
    async updateVerification(@Req() req: any, @Body() body: { idCardUrl: string; selfieUrl: string }) {
        return this.userService.updateVerification(req.user.uid, {
            idCardUrl: body.idCardUrl,
            selfieUrl: body.selfieUrl,
            submitted: true
        });
    }

    @Put('device-token')
    async updateDeviceToken(@Req() req: any, @Body() body: { fcmToken: string }) {
        return this.userService.updateDeviceToken(req.user.uid, body.fcmToken);
    }

    @Post('presence')
    async updatePresence(@Req() req: any, @Body() body: { isOnline: boolean }) {
        return this.userService.updatePresence(req.user.uid, body.isOnline);
    }
}
