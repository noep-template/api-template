/* eslint-disable @typescript-eslint/no-empty-interface */
/* eslint-disable @typescript-eslint/no-empty-function */
import {
  BadRequestException,
  Controller,
  HttpCode,
  Inject,
  Post,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth } from '@nestjs/swagger';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { v4 as uuid } from 'uuid';
import { GetCurrentUser } from '../../decorators/get-current-user.decorator';
import { MediaService } from '../media/media.service';
import { errorMessage } from '@web-template/errors';
import { User } from '../users/user.entity';

export function replaceAll(str: string, find: string, replace: string) {
  return str.replace(new RegExp(find, 'g'), replace);
}

@Controller('file-upload')
export class FileUploadController {
  constructor(
    @Inject(MediaService)
    private mediaService: MediaService,
  ) {}
  // TUTORIAL : https://gabrieltanner.org/blog/nestjs-file-uploading-using-multer

  @Post('/')
  @ApiBearerAuth()
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: './public/files',
        filename: (req, file, callback) => {
          const fileExtName = extname(file.originalname);
          const randomName = uuid();
          const encodedName = replaceAll(
            `${randomName}${fileExtName}`,
            ' ',
            '-',
          );
          callback(null, encodedName);
        },
      }),
      limits: { fileSize: 104857600 }, // 100Mb:
      fileFilter: (req, file, callback) => {
        const allowedExtensions = /\.(jpg|jpeg|png|pdf)$/;
        const extension = allowedExtensions.exec(file.originalname);
        if (!extension) {
          return callback(
            new BadRequestException(errorMessage.api('file').INVALID_FORMAT),
            false,
          );
        }
        callback(null, true);
      },
    }),
  )
  @HttpCode(201)
  async upload(
    @UploadedFile() file: Express.Multer.File,
    @GetCurrentUser() user: User,
  ) {
    return await this.mediaService.createMedia(file, user);
  }
}
