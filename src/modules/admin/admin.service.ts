import { errorMessage } from '@/errors';
import {
  BadRequestException,
  Inject,
  Injectable,
  forwardRef,
} from '@nestjs/common';
import { Repository } from 'typeorm';
import { AuthService } from '../auth/auth.service';
import { User } from '../user/user.entity';
import { InjectRepository } from '@nestjs/typeorm';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(User) private adminRepository: Repository<User>,
    @Inject(forwardRef(() => AuthService))
    private authService: AuthService,
  ) {}

  async loadAdmin() {
    const adminBody = {
      firstName: 'admin',
      lastName: 'admin',
      email: 'admin@gmail.com',
      password: 'Azerty12!',
      isAdmin: true,
    };
    try {
      const possibleAdmin = await this.adminRepository.find({
        where: { isAdmin: true },
      });
      if (possibleAdmin.length)
        throw new BadRequestException(
          errorMessage.api('admin').ALREADY_CREATED,
        );
      const { access_token } = await this.authService.register(adminBody);
      return access_token;
    } catch (error) {
      throw new BadRequestException(error);
    }
  }
}
