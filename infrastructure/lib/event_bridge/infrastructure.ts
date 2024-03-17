import { RemovalPolicy, Stack } from 'aws-cdk-lib';
import { EventBus, Rule }from 'aws-cdk-lib/aws-events';
import { CloudWatchLogGroup } from 'aws-cdk-lib/aws-events-targets';
import { PolicyStatement } from 'aws-cdk-lib/aws-iam';
import { LogGroup, RetentionDays } from 'aws-cdk-lib/aws-logs';
import { Bucket } from 'aws-cdk-lib/aws-s3';
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

    const gameplayEventsBusLogGroup = new LogGroup(this, 'GameplayEventsLogGroup', {
      retention: RetentionDays.ONE_DAY,
      removalPolicy: RemovalPolicy.DESTROY,
      logGroupName: Stack.of(this).stackName + 'GameplayEventsLogGroup'
    });

    new Rule(this, 'GameplayEventsLogRule', {
      eventBus: this.gameplayEventsBus,
      eventPattern: {
        source: ['custom.gameplay', 'custom.cognito']
      }
    }).addTarget(new CloudWatchLogGroup(gameplayEventsBusLogGroup));
  }
}
