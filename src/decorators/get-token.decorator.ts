import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { User } from '@/modules/user/user.entity';

export const GetUserToken = createParamDecorator(
  (_, context: ExecutionContext): User => {
    const request = context.switchToHttp().getRequest();
    const [, token] = request.headers.authorization.split(' ');
    return token;
  },
);
