import { MigrationInterface, QueryRunner } from 'typeorm';

export class Initialmigration1747098396320 implements MigrationInterface {
  name = 'Initialmigration1747098396320';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "sentiment" ("id" SERIAL NOT NULL, "summary" text NOT NULL, "sentiment" text, "originalText" text NOT NULL, "score" double precision, "magnitude" double precision, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_c98a88ddb0495dd509e50a0b563" PRIMARY KEY ("id"))`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "sentiment"`);
  }
}
