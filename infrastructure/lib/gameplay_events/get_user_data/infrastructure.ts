import { Construct } from 'constructs';
import { RetentionDays } from 'aws-cdk-lib/aws-logs';
import { Code, Function, Runtime } from 'aws-cdk-lib/aws-lambda';
import { Duration } from 'aws-cdk-lib';
import { GameplayDDB } from '../../db/infrastructure';
import { GameplayStaticsStore } from '../../assets_store/infrastructure';
import { EventJob } from '..';
import { EventBusik } from '../../event_bridge/infrastructure';
import { WebhookApi } from '../../api/infrastructure';

interface GetGameplayDataJobProps {
  gameplayDDB: GameplayDDB;
  gameplayWS: WebhookApi;
}

export class GetGameplayDataJob extends EventJob {
  readonly handler: Function;

  constructor(scope: Construct, id: string, props: GetGameplayDataJobProps) {
    super(scope, id);

    const { gameplayDDB, gameplayWS } = props

    this.handler = new Function(this, 'SetupNewUserJob', {
      runtime: Runtime.RUBY_3_2,
      timeout: Duration.seconds(10),
      handler: 'main.handler',
      code: Code.fromAsset('vendor/gameplay_backend/jobs/get_user_data'),
      environment: {
        USERS_TABLE_NAME: gameplayDDB.tables.users.tableName,
        APIGW_ENDPOINT: gameplayWS.stage.url.replace('wss://', 'https://')
      },
      logRetention: RetentionDays.ONE_WEEK,
      initialPolicy: [
        gameplayDDB.policies.listTables,
      ]
    })

    gameplayWS.api.grantManageConnections(this.handler);
    gameplayDDB.tables.users.grantReadWriteData(this.handler);
  }
}