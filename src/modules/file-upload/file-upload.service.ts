import { Injectable } from '@nestjs/common';
import { MediaType } from '@/types';

@Injectable()
export class FileUploadService {
  detectFileType(fileName: string): MediaType {
    const fileExtension = fileName.split('.').pop().toLowerCase();
    if (
      fileExtension === 'png' ||
      fileExtension === 'jpg' ||
      fileExtension === 'jpeg'
    )
      return MediaType.IMAGE;
    else return MediaType.FILE;
  }

  getLocalFilePathFromUrl(url: string): string {
    return `${process.env.FILES_PATH}/${url.split('/').pop()}`;
  }
}
