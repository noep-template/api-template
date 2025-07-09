import { MiddlewareConsumer, Module, RequestMethod, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthMiddleware } from '../auth/auth.middleware';
import { AuthModule } from '../auth/auth.module';
import { MediaModule } from '../media/media.module';
import { User } from '../user/user.entity';
import { UserModule } from '../user/user.module';
import { AdminService } from './admin.service';
import { AdminUsersController } from './users.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([User]),
    forwardRef(() => UserModule),
    forwardRef(() => AuthModule),
    forwardRef(() => MediaModule),
  ],
  providers: [AdminService],
  controllers: [AdminUsersController],
})
export class AdminModule {
  public configure(consumer: MiddlewareConsumer) {
    consumer
      .apply(AuthMiddleware)
      .forRoutes(
        { path: '/admin', method: RequestMethod.ALL },
        { path: '/admin/*path', method: RequestMethod.ALL },
      );
  }
}
