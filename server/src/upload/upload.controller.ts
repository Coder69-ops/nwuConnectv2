
import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { R2Service } from '../common/services/r2.service';

@Controller('upload')
@UseGuards(FirebaseAuthGuard)
export class UploadController {
    constructor(private readonly r2Service: R2Service) { }

    @Post('presigned-url')
    async getPresignedUrl(@Body() body: { mimeType: string }) {
        return this.r2Service.generatePresignedUrl(body.mimeType);
    }
}
