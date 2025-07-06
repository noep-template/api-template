import {
  forwardRef,
  MiddlewareConsumer,
  Module,
  RequestMethod,
} from '@nestjs/common';
import { AuthMiddleware } from '../auth/auth.middleware';
import { AuthModule } from '../auth/auth.module';
import { MediaModule } from '../media/media.module';
import { UserModule } from '../user/user.module';
import { FileUploadController } from './file-upload.controller';
import { FileUploadService } from './file-upload.service';
import { ImageOptimizerService } from './image-optimizer.service';
import { OptimizationConfigService } from './optimization-config.service';

@Module({
  imports: [
    forwardRef(() => AuthModule),
    forwardRef(() => MediaModule),
    forwardRef(() => UserModule),
  ],
  providers: [
    FileUploadService,
    ImageOptimizerService,
    OptimizationConfigService,
  ],
  controllers: [FileUploadController],
  exports: [
    FileUploadService,
    ImageOptimizerService,
    OptimizationConfigService,
  ],
})
export class FileUploadModule {
  public configure(consumer: MiddlewareConsumer) {
    consumer
      .apply(AuthMiddleware)
      .forRoutes(
        { path: '/upload', method: RequestMethod.ALL },
        { path: '/upload/*', method: RequestMethod.ALL },
      );
  }
}
