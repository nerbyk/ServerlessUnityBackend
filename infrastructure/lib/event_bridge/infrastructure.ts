import { Duration, Stack } from 'aws-cdk-lib';
import { EventBus, Rule }from 'aws-cdk-lib/aws-events';
import { LambdaFunction } from 'aws-cdk-lib/aws-events-targets';
import { PolicyStatement } from 'aws-cdk-lib/aws-iam';
import { Code, Runtime, Function } from 'aws-cdk-lib/aws-lambda';
import { RetentionDays } from 'aws-cdk-lib/aws-logs';
import { Construct } from 'constructs';

export class EventBusik extends Construct {
  readonly gameplayEventsBus: EventBus;
  readonly putEventsPolicy: PolicyStatement;

  constructor(scope: Construct, id: string) {
    super(scope, id);

    this.gameplayEventsBus = new EventBus(this, 'EventBridge', {
      eventBusName: "GameplayEvents"
    })

    this.putEventsPolicy = new PolicyStatement({
      actions: ['events:PutEvents'],
      resources: [this.gameplayEventsBus.eventBusArn]
    });
  }
}
