import { Stack } from 'aws-cdk-lib';
import { EventBus, Rule, RuleProps }from 'aws-cdk-lib/aws-events';
import { LambdaFunction } from 'aws-cdk-lib/aws-events-targets';
import { PolicyStatement } from 'aws-cdk-lib/aws-iam';
import { Function } from 'aws-cdk-lib/aws-lambda';
import { Construct } from 'constructs';

export class EventBusik extends Construct {
  readonly gameplayEventsBus: EventBus;
  readonly putEventsPolicy: PolicyStatement;

  constructor(scope: Construct, id: string) {
    super(scope, id);

    this.gameplayEventsBus = new EventBus(this, 'EventBridge', {
      eventBusName: Stack.of(this).stackName + 'GameplayEvents'
    })

    this.putEventsPolicy = new PolicyStatement({
      actions: ['events:PutEvents'],
      resources: [this.gameplayEventsBus.eventBusArn]
    });
  }
}
