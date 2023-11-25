import { errorMessage } from '@/errors';
import { AuthLoginApi, TechRegisterApi } from '@/types';
import {
  BadRequestException,
  Inject,
  Injectable,
  NotFoundException,
  forwardRef,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt/dist/jwt.service';
import * as bcrypt from 'bcryptjs';
import { UserService } from '../user/user.service';
import { AuthValidation } from './auth.validation';

@Injectable()
export class AuthService {
  constructor(
    @Inject(forwardRef(() => UserService))
    private userRepository: UserService,
    private authValidation: AuthValidation,
    private jwtService: JwtService,
  ) {}

  async login(body: AuthLoginApi) {
    const user = await this.userRepository.getOneByEmail(body.email);
    if (!user)
      throw new NotFoundException(
        errorMessage.api('user').NOT_FOUND_OR_WRONG_PASSWORD,
      );
    if (body.password)
      await this.authValidation.validateUser(body.email, body.password);
    const payload = { email: user.email, id: user.id };
    return {
      access_token: this.jwtService.sign(payload),
    };
  }

  async register(body: TechRegisterApi) {
    const { password, email } = body;
    const possibleUser = await this.userRepository.getOneByEmail(email);
    if (possibleUser)
      throw new BadRequestException(errorMessage.api('user').EXIST);
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
