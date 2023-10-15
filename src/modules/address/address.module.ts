import {
  MiddlewareConsumer,
  Module,
  RequestMethod,
  forwardRef,
} from '@nestjs/common';
import { AddressService } from './address.service';
import { Address } from './address.entity';
import { UsersModule } from '../users/users.module';
import { AuthModule } from '../auth/auth.module';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthMiddleware } from '../auth/auth.middleware';

@Module({
  imports: [
    TypeOrmModule.forFeature([Address]),
    forwardRef(() => UsersModule),
    forwardRef(() => AuthModule),
  ],
  providers: [AddressService],
  exports: [AddressService],
})
export class AddressModule {
  public configure(consumer: MiddlewareConsumer) {
    consumer
      .apply(AuthMiddleware)
      .forRoutes(
        { path: '/address', method: RequestMethod.ALL },
        { path: '/address/*', method: RequestMethod.ALL },
      );
  }
}
