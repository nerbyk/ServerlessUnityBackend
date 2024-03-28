import { Construct } from 'constructs';
import { RetentionDays } from 'aws-cdk-lib/aws-logs';
import { Code, Function, Runtime } from 'aws-cdk-lib/aws-lambda';
import { Duration } from 'aws-cdk-lib';
import { GameplayDDB } from '../../db/infrastructure';
import { EventJob } from '..';

interface GetGameplayDataJobProps {
  gameplayDDB: GameplayDDB;
}

export class GetGameplayDataJob extends EventJob {
  readonly handler: Function;

  constructor(scope: Construct, id: string, props: GetGameplayDataJobProps) {
    super(scope, id);

    const { gameplayDDB } = props

    this.handler = new Function(this, 'GetUserDataJob', {
      runtime: Runtime.RUBY_3_2,
      timeout: Duration.seconds(30),
      handler: 'main.handler',
      code: Code.fromAsset('vendor/gameplay_backend/jobs/get_user_data'),
      environment: {
        USERS_TABLE_NAME: gameplayDDB.tables.users.tableName
      },
      logRetention: RetentionDays.ONE_DAY,
      initialPolicy: [
        gameplayDDB.policies.listTables,
      ]
    })

    gameplayDDB.tables.users.grantReadWriteData(this.handler);
  }
}