import { EventBus, Rule, RuleProps } from "aws-cdk-lib/aws-events";
import { Construct } from "constructs";
import { Function } from "aws-cdk-lib/aws-lambda";
import { LambdaFunction } from "aws-cdk-lib/aws-events-targets";

export class EventJob extends Construct {
  readonly handler: Function;
}

import { SetupNewUserJob } from "./user_signup_confirmed/infrastructure";
import { GetGameplayDataJob } from "./get_user_data/infrastructure";

export class EventJobs {
  static SetupNewUserJob = SetupNewUserJob;
  static GetGameplayDataJob = GetGameplayDataJob;
}

export class EventJobBuilder {
  private jobInstance: EventJob;
  private eventBus: EventBus;

  private constructor(jobInstance: EventJob, eventBus: EventBus) {
    this.jobInstance = jobInstance;
    this.eventBus = eventBus;
  }

  static new(job: EventJob, eventBus: EventBus): EventJobBuilder {
    return new EventJobBuilder(job, eventBus);
  }

  addTrigger(triggerName: string, triggerProps: RuleProps): EventJobBuilder {
    new Rule(this.jobInstance, triggerName, { eventBus: this.eventBus, ...triggerProps })
      .addTarget(new LambdaFunction(this.jobInstance.handler));

    return this;
  }

  build(): EventJob {
    return this.jobInstance;
  }
}

export class EventStore {
  public static UserSignupConfirmedRuleProps: RuleProps = {
    description: "User confirmed signup",
    eventPattern: {
      source: ['custom.cognito'],
      detailType: ['USER_SIGN_UP_CONFIRMED'],
    }
  }

  public static GetUserDataRuleProps: RuleProps = {
    description: "Get user data",
    eventPattern: {
      source: ['custom.gameplay_backend'],
      detailType: ['GET_USER_DATA'],
    }
  }
}
