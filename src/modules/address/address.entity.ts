import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity()
export class Address {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ default: '' })
  street: string;

  @Column({ default: '' })
  city: string;

  @Column({ default: '' })
  zipCode: string;

  @Column({ default: '' })
  country: string;
}
