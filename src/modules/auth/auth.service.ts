import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt/dist/jwt.service';
import * as bcrypt from 'bcryptjs';
import { AuthLoginApi, AuthRegisterApi } from '@web-template/types';
import { UsersService } from '../users/users.service';
import { AuthValidation } from './auth.validation';
import { validationUser } from '@web-template/validations';
import { errorMessage } from '@web-template/errors';

@Injectable()
export class AuthService {
  constructor(
    private userRepository: UsersService,
    private authValidation: AuthValidation,
    private jwtService: JwtService,
  ) {}

  async login(body: AuthLoginApi) {
    try {
      await validationUser.login.validate(body, {
        abortEarly: false,
      });
    } catch (e) {
      throw new BadRequestException(e.errors);
    }
    const user = await this.userRepository.findOneByEmail(body.email);
    if (!user)
      throw new NotFoundException(
        errorMessage.api('user').NOT_FOUND_OR_WRONG_PASSWORD,
      );
    await this.authValidation.validateUser(body.email, body.password);
    const payload = { email: user.email, id: user.id };
    return {
      access_token: this.jwtService.sign(payload),
    };
  }

  async register(body: AuthRegisterApi) {
    try {
      await validationUser.create.validate(body, {
        abortEarly: false,
      });
    } catch (e) {
      throw new BadRequestException(e.errors);
    }
    const possibleUser = await this.userRepository.findOneByEmail(body.email);
    if (possibleUser)
      throw new BadRequestException(errorMessage.api('user').EXIST);
    const { email, password } = body;
    const encryptedPassword = await this.encryptPassword(password);
    const createdUser = await this.userRepository.createUser({
      ...body,
      password: encryptedPassword,
    });
    return {
      access_token: await this.login({ email, password }),
      user: createdUser,
    };
  }

  async encryptPassword(password: string): Promise<string> {
    return await bcrypt.hash(password, await bcrypt.genSalt(10));
  }
}
