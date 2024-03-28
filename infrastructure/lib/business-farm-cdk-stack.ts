import { Stack, StackProps } from 'aws-cdk-lib';
import { Construct } from 'constructs';

import { CognitoAuth } from './auth/infrastructure';
import { EventBusik } from './event_bridge/infrastructure';
import { GameplayDDB } from './db/infrastructure';
import { GameplayStaticsStore } from './assets_store/infrastructure';
import { EventStore, EventJobBuilder, EventJobs } from './gameplay_events'
import { WebhookAndRestApi } from './api/infrastructure';
import { Integration, IntegrationType, LambdaIntegration } from 'aws-cdk-lib/aws-apigateway';
import { Role, ServicePrincipal } from 'aws-cdk-lib/aws-iam';
import * as openapix from '@alma-cdk/openapix';
import path = require('path');

export class BusinessFarmCdkStack extends Stack {
  constructor(scope: Construct, id: string, props?: StackProps) {
    super(scope, id);

    const eventBridge = new EventBusik(this, `EventBus`);
    const staticStore = new GameplayStaticsStore(this, `GameplayStaticsStore`)
    const gameplayDDB = new GameplayDDB(this, `GameplayDDB`);
    const auth = new CognitoAuth(this, `CognitoAuth`, { gameplayEB: eventBridge });
    const api =  new WebhookAndRestApi(this, `WebhookApi`, { auth, eventBridge, restApiFunctions: {
      getUserData: new EventJobs.GetGameplayDataJob(this, "GetUserDataJob", { gameplayDDB }).handler
    } });

    this.buildEventJobs(eventBridge, gameplayDDB, staticStore, api);
  }

  private buildEventJobs(gameplayEB: EventBusik, gameplayDDB: GameplayDDB, gameplayStatics: GameplayStaticsStore, gameplayWS: WebhookAndRestApi) {
    const setupNewUserEventJob = new EventJobs.SetupNewUserJob(this, "SetupNewUserJob", { gameplayDDB, gameplayStatics })

    EventJobBuilder
      .new(setupNewUserEventJob, gameplayEB.gameplayEventsBus)
      .addTrigger("UserSignUpConfirmedJobTrigger", EventStore.UserSignupConfirmedRuleProps);
  }
}
