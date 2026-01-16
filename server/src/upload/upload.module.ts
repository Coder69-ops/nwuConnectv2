
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { UploadController } from './upload.controller';
import { R2Service } from '../common/services/r2.service';

@Module({
    imports: [ConfigModule],
    controllers: [UploadController],
    providers: [R2Service],
    exports: [R2Service],
})
export class UploadModule { }
