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

    this.createNewUserRule(this.gameplayEventsBus)
  }

  private createNewUserRule(eventBus: EventBus) {
    const newUserLambda = new Function(this, 'SetupNewUserJob', {
      runtime: Runtime.RUBY_3_2,
      timeout: Duration.seconds(10),
      handler: 'main.handler',
      code: Code.fromAsset('../gameplay_backend/new_user'),
      logRetention: RetentionDays.ONE_WEEK
    })

    new Rule(this, 'UserSignUpConfirmedRule', {
      description: 'When a user signs up and confirms their email, setup game data',
      eventPattern: {
        source: ['custom.cognito'],
        detailType: ['USER_SIGN_UP_CONFIRMED']
      },
      eventBus
    }).addTarget(new LambdaFunction(newUserLambda))
  }
}
