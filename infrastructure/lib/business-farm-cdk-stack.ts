import { Stack, StackProps } from 'aws-cdk-lib';
import { Construct } from 'constructs';

import { CognitoAuth } from './auth/infrastructure';
import { EventBusik } from './event_bridge/infrastructure';
import { GameplayDDB } from './db/infrastructure';
import { GameplayStaticsStore } from './assets_store/infrastructure';
import { EventStore, EventJobBuilder, EventJobs } from './gameplay_events'
import { WebhookApi } from './api/infrastructure';

export class BusinessFarmCdkStack extends Stack {
  constructor(scope: Construct, id: string, props?: StackProps) {
    super(scope, id);

    const eventBridge = new EventBusik(this, `EventBus`);
    const staticStore = new GameplayStaticsStore(this, `GameplayStaticsStore`)
    const gameplayDDB = new GameplayDDB(this, `GameplayDDB`);
    const auth = new CognitoAuth(this, `CognitoAuth`, { gameplayEB: eventBridge });
    const websocketApi = new WebhookApi(this, `WebhookApi`, { auth, eventBridge });

    this.buildEventJobs(eventBridge, gameplayDDB, staticStore, websocketApi);
  }

  private buildEventJobs(gameplayEB: EventBusik, gameplayDDB: GameplayDDB, gameplayStatics: GameplayStaticsStore, gameplayWS: WebhookApi) {
    const setupNewUserEventJob = new EventJobs.SetupNewUserJob(this, "SetupNewUserJob", { gameplayDDB, gameplayStatics })
    const getGameplayDataEventJob = new EventJobs.GetGameplayDataJob(this, "GetGameplayDataJob", { gameplayDDB, gameplayWS })


    EventJobBuilder
      .new(setupNewUserEventJob, gameplayEB.gameplayEventsBus)
      .addTrigger("UserSignUpConfirmedJobTrigger", EventStore.UserSignupConfirmedRuleProps);

    EventJobBuilder
      .new(getGameplayDataEventJob, gameplayEB.gameplayEventsBus)
      .addTrigger("GameplayDataRequestedJobTrigger", EventStore.GetUserDataRuleProps);
  }
}
