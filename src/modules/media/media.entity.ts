import { MediaType } from '@web-template/types';
import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity()
export class Media {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  url: string;

  @Column({ nullable: false, default: '' })
  localPath: string;

  @Column({ nullable: false, default: '' })
  filename: string;

  @Column()
  type: MediaType;

  @Column()
  size: number;
}
