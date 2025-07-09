import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { Strategy } from 'passport-local';
import { AuthValidation } from '../auth.validation';

@Injectable()
export class LocalStrategy extends PassportStrategy(Strategy) {
  constructor(private authValidation: AuthValidation) {
    super();
  }

  async validate(username: string, password: string): Promise<any> {
    return this.authValidation.validateUser(username, password);
  }
}
