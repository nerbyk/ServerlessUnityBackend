import { Stack, StackProps } from 'aws-cdk-lib';
import { Construct } from 'constructs';

import { CognitoAuth } from './auth/infrastructure';
import { EventBusik } from './event_bridge/infrastructure';
import { GameplayDDB } from './db/infrastructure';
import { GameplayStaticsStore } from './assets_store/infrastructure';
import * as EventJobs from './gameplay_events'

export class BusinessFarmCdkStack extends Stack {
  constructor(scope: Construct, id: string, props?: StackProps) {
    super(scope, id);

    const eventBridge = new EventBusik(this, `EventBus`);
    const staticStore = new GameplayStaticsStore(this, `GameplayStaticsStore`)
    const auth = new CognitoAuth(this, `CognitoAuth`, { 
      gameplayEB: eventBridge
    });
    const db = new GameplayDDB(this, `GameplayDDB`);

    new EventJobs.UserSignupConfirmedEvent(this, `SetupNewUserJob`, {
      gameplayEB:  eventBridge,
      gameplayDDB: db,
      gameplayStatics: staticStore
    })
  }
}
