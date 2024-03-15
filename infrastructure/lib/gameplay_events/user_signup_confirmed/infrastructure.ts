import { Construct } from 'constructs';
import { RetentionDays } from 'aws-cdk-lib/aws-logs';
import { Code, Function, Runtime } from 'aws-cdk-lib/aws-lambda';
import { Duration } from 'aws-cdk-lib';
import { GameplayDDB } from '../../db/infrastructure';
import { GameplayStaticsStore } from '../../assets_store/infrastructure';
import { EventJob } from '..';

interface UserSignupConfirmedProps {
  gameplayDDB: GameplayDDB;
  gameplayStatics: GameplayStaticsStore;
}

export class SetupNewUserJob extends EventJob {
  readonly handler: Function;

  constructor(scope: Construct, id: string, props: UserSignupConfirmedProps) {
    super(scope, id);

    const { gameplayDDB, gameplayStatics } = props

    this.handler = new Function(this, 'SetupNewUserJob', {
      runtime: Runtime.RUBY_3_2,
      timeout: Duration.seconds(10),
      handler: 'main.handler',
      code: Code.fromAsset('vendor/gameplay_backend/jobs/new_user'),
      environment: {
        USERS_TABLE_NAME: gameplayDDB.tables.users.tableName,
        STATICS_S3_BUCKET_NAME: gameplayStatics.staticsStore.bucketName
      },
      logRetention: RetentionDays.ONE_WEEK,
      initialPolicy: [
        gameplayDDB.policies.listTables
      ]
    })

    gameplayDDB.tables.users.grantReadWriteData(this.handler);
    gameplayStatics.staticsStore.grantRead(this.handler);
  }
}