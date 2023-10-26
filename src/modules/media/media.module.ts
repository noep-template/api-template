import {
  forwardRef,
  MiddlewareConsumer,
  Module,
  RequestMethod,
} from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthMiddleware } from '../auth/auth.middleware';
import { AuthModule } from '../auth/auth.module';
import { MediaService } from './media.service';
import { Media } from './media.entity';
import { UsersModule } from '../users/users.module';
import { FileUploadModule } from '../file-upload/file-upload.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Media]),
    forwardRef(() => AuthModule),
    forwardRef(() => UsersModule),
    forwardRef(() => FileUploadModule),
  ],
  providers: [MediaService],
  controllers: [],
  exports: [TypeOrmModule, MediaService],
})
export class MediaModule {
  public configure(consumer: MiddlewareConsumer) {
    consumer
      .apply(AuthMiddleware)
      .forRoutes(
        { path: '/media', method: RequestMethod.ALL },
        { path: '/media/*', method: RequestMethod.ALL },
      );
  }
}
