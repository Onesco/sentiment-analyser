import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

@Entity('sentiment')
export class SentimentEntity {
  @PrimaryGeneratedColumn()
  id!: string;

  @Column('text')
  summary!: string;

  @Column('text', { nullable: true })
  sentiment!: string | null;

  @Column('text')
  originalText!: string;

  @Column('float', { nullable: true })
  score!: number | null;

  @Column('float', { nullable: true })
  magnitude!: number | null;

  @CreateDateColumn({ type: 'timestamp' })
  createdAt!: Date;
}
