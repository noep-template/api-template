import {
  Injectable,
  NestMiddleware,
  UnauthorizedException,
} from '@nestjs/common';
import { NextFunction, Request, Response } from 'express';
import * as jwt from 'jsonwebtoken';
import { UsersService } from '../users/users.service';

@Injectable()
export class AuthMiddleware implements NestMiddleware {
  constructor(private readonly userRepository: UsersService) {}

  async use(req: Request, res: Response, next: NextFunction) {
    const authHeaders = req.headers.authorization;
    if (authHeaders && (authHeaders as string).split(' ')[1]) {
      try {
        const token = (authHeaders as string).split(' ')[1];
        const decoded: any = jwt.verify(token, process.env.JWT_SECRET);
        const user = await this.userRepository.getUser(decoded.id);
        if (!user) {
          throw new UnauthorizedException();
        }
        req.user = user;
        next();
      } catch (e) {
        throw new UnauthorizedException();
      }
    } else {
      throw new UnauthorizedException();
    }
  }
}
