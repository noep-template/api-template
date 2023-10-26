import {
  forwardRef,
  MiddlewareConsumer,
  Module,
  RequestMethod,
} from '@nestjs/common';
import { AuthMiddleware } from '../auth/auth.middleware';
import { AuthModule } from '../auth/auth.module';
import { MediaModule } from '../media/media.module';
import { FileUploadService } from './file-upload.service';
import { FileUploadController } from './file-upload.controller';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [
    forwardRef(() => AuthModule),
    forwardRef(() => MediaModule),
    forwardRef(() => UsersModule),
  ],
  providers: [FileUploadService],
  controllers: [FileUploadController],
  exports: [FileUploadService],
})
export class FileUploadModule {
  public configure(consumer: MiddlewareConsumer) {
    consumer
      .apply(AuthMiddleware)
      .forRoutes(
        { path: '/file-upload', method: RequestMethod.ALL },
        { path: '/file-upload/*', method: RequestMethod.ALL },
      );
  }
}
