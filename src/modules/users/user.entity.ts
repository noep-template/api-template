import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { Address } from '../address/address.entity';
import { Media } from '../media/media.entity';

@Entity()
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 25 })
  lastName: string;

  @Column({ length: 25 })
  firstName: string;

  @Column({})
  email: string;

  @Column({})
  password: string;

  @Column({ default: false })
  isAdmin: boolean;

  @OneToOne(() => Address, { cascade: true, eager: true, nullable: true })
  @JoinColumn()
  address: Address;

  @OneToOne(() => Media, { cascade: true, eager: true, nullable: true })
  @JoinColumn()
  profilePicture: Media;
}
