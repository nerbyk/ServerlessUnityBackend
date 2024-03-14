import { Construct } from 'constructs';
import { RetentionDays } from 'aws-cdk-lib/aws-logs';
import { ITable } from 'aws-cdk-lib/aws-dynamodb';
import { Code, Function, Runtime } from 'aws-cdk-lib/aws-lambda';
import { Duration } from 'aws-cdk-lib';
import { EventBus, Rule } from 'aws-cdk-lib/aws-events';
import { LambdaFunction } from 'aws-cdk-lib/aws-events-targets';
import { GameplayDDB } from '../../db/infrastructure';
import { EventBusik } from '../../event_bridge/infrastructure';
import { GameplayStaticsStore } from '../../assets_store/infrastructure';
import { Role } from 'aws-cdk-lib/aws-iam';

interface UserSignupConfirmedProps {
  gameplayDDB: GameplayDDB;
  gameplayEB: EventBusik;
  gameplayStatics: GameplayStaticsStore;
}

export class UserSignupConfirmedEvent extends Construct {
  constructor(scope: Construct, id: string, props: UserSignupConfirmedProps) {
    super(scope, id);

    const { gameplayDDB, gameplayEB, gameplayStatics} = props

    const newUserLambda = new Function(this, 'SetupNewUserJob', {
      runtime: Runtime.RUBY_3_2,
      timeout: Duration.seconds(10),
      handler: 'main.handler',
      code: Code.fromAsset('vendor/gameplay_backend/jobs/new_user'),
      environment: {
        ENTITY_TABLE_NAME: gameplayDDB.gameEntitiesTable.tableName,
        ENTITY_RECEIPT_TABLE_NAME: gameplayDDB.gameEntitiesReceiptsTable.tableName,
        ITEM_TABLE_NAME: gameplayDDB.gameItemsTable.tableName,
      },
      logRetention: RetentionDays.ONE_WEEK
    })

    gameplayDDB.gameEntitiesReceiptsTable.grantReadWriteData(newUserLambda);
    gameplayDDB.gameEntitiesTable.grantReadWriteData(newUserLambda);
    gameplayDDB.gameItemsTable.grantReadWriteData(newUserLambda);
    gameplayDDB.gameUsersTable.grantReadWriteData(newUserLambda);
    gameplayStatics.staticsStore.grantRead(newUserLambda);

    new Rule(this, 'UserSignUpConfirmedRule', {
      description: 'When a user signs up and confirms their email, setup game data',
      eventPattern: {
        source: ['custom.cognito'],
        detailType: ['USER_SIGN_UP_CONFIRMED']
      },
      ...gameplayEB.gameplayEventsBus
    }).addTarget(new LambdaFunction(newUserLambda));
  }
}