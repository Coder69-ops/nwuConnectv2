import { Controller, Get, Patch, Param, Body, Query, UseGuards } from '@nestjs/common';
import { AdminService } from './admin.service';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
// TODO: Add AdminRoleGuard to ensure only admins can access

@Controller('admin')
@UseGuards(FirebaseAuthGuard)
export class AdminController {
    constructor(private readonly adminService: AdminService) { }

    @Get('stats')
    getStats() {
        return this.adminService.getStats();
    }

    @Get('verifications')
    getVerifications() {
        return this.adminService.getVerifications();
    }

    @Get('users')
    getAllUsers(@Query('limit') limit: number, @Query('skip') skip: number) {
        return this.adminService.getAllUsers(limit, skip);
    }

    @Patch('users/:id/approve')
    approveUser(@Param('id') id: string) {
        return this.adminService.approveUser(id);
    }

    @Patch('users/:id/reject')
    rejectUser(@Param('id') id: string, @Body('reason') reason: string) {
        return this.adminService.rejectUser(id, reason);
    }

    @Patch('users/:id/ban')
    banUser(@Param('id') id: string) {
        return this.adminService.banUser(id);
    }

    @Patch('users/:id/unban')
    unbanUser(@Param('id') id: string) {
        return this.adminService.unbanUser(id);
    }

    @Get('reports')
    getReports() {
        return this.adminService.getReports();
    }

    @Patch('reports/:id/resolve')
    resolveReport(@Param('id') id: string) {
        return this.adminService.resolveReport(id);
    }

    @Patch('reports/:id/dismiss')
    dismissReport(@Param('id') id: string) {
        return this.adminService.dismissReport(id);
    }

    @Patch('broadcast')
    sendBroadcast(@Body() body: { title: string, message: string }) {
        return this.adminService.sendBroadcast(body.title, body.message);
    }
}
