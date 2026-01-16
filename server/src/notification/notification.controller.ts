import { Controller, Get, Post, Param, Req, UseGuards, Put } from '@nestjs/common';
import { NotificationService } from './notification.service';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';

@Controller('notifications')
@UseGuards(FirebaseAuthGuard)
export class NotificationController {
    constructor(private readonly notificationService: NotificationService) { }

    @Get()
    async getUserNotifications(@Req() req: any) {
        return this.notificationService.getUserNotifications(req.user.uid);
    }

    @Put(':id/read')
    async markAsRead(@Param('id') id: string) {
        return this.notificationService.markAsRead(id);
    }

    @Put('read-all')
    async markAllAsRead(@Req() req: any) {
        return this.notificationService.markAllAsRead(req.user.uid);
    }
}
