import {
  Injectable,
  NestMiddleware,
  UnauthorizedException,
} from '@nestjs/common';
import { NextFunction, Request, Response } from 'express';
import * as jwt from 'jsonwebtoken';
import { UserService } from '../user/user.service';

@Injectable()
export class AuthMiddleware implements NestMiddleware {
  constructor(private readonly userRepository: UserService) {}

  async use(req: Request, res: Response, next: NextFunction) {
    const authHeaders = req.headers.authorization;
    if (authHeaders && (authHeaders as string).split(' ')[1]) {
      try {
        const token = (authHeaders as string).split(' ')[1];
        const decoded: any = jwt.verify(token, process.env.JWT_SECRET);
        const user = await this.userRepository.getOneById(decoded.id);
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
