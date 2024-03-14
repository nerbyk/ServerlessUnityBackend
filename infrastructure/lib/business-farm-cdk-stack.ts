import { Stack, StackProps } from 'aws-cdk-lib';
import { Construct } from 'constructs';
import { CognitoAuth } from './auth/infrastructure';
import { EventBusik } from './event_bridge/infrastructure';

export class BusinessFarmCdkStack extends Stack {
  constructor(scope: Construct, id: string, props?: StackProps) {
    super(scope, id);

    const eventBus = new EventBusik(this, `EventBus`);
    const auth = new CognitoAuth(this, `CognitoAuth`, { 
      event_bridge: eventBus
    });
  }
}
