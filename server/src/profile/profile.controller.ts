
import { Body, Controller, Get, Put, Req, UseGuards } from '@nestjs/common';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { ProfileService } from './profile.service';

@Controller('profile')
@UseGuards(FirebaseAuthGuard)
export class ProfileController {
    constructor(private readonly profileService: ProfileService) { }

    @Get()
    async getProfile(@Req() req: any) {
        return this.profileService.getProfile(req.user.uid);
    }

    @Put()
    async updateProfile(@Req() req: any, @Body() body: { name: string; bio: string; department: string; interests?: string[] }) {
        return this.profileService.upsertProfile(req.user.uid, body);
    }
}
