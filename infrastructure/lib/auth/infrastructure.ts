import { Construct } from 'constructs';
import { UserPool, UserPoolClient, UserPoolOperation, AccountRecovery, VerificationEmailStyle } from 'aws-cdk-lib/aws-cognito';
import { StringParameter } from 'aws-cdk-lib/aws-ssm';
import { Code, Function, Runtime } from 'aws-cdk-lib/aws-lambda';
import { Stack } from 'aws-cdk-lib';
import { PolicyStatement } from 'aws-cdk-lib/aws-iam';
import { EventBusik } from '../event_bridge/infrastructure';

type CognitoAuthProps = {
  event_bridge: EventBusik;
};

export class CognitoAuth extends Construct {
  readonly userPool: UserPool;
  readonly userPoolName: string;
  readonly userPoolClient: UserPoolClient;

  constructor(scope: Construct, id: string, props: CognitoAuthProps) {
    super(scope, id);

    this.userPool =  new UserPool(this, `CognitoUserPool`, {
      selfSignUpEnabled: true,
      signInAliases: {
        email: true,
        username: false
      },
      standardAttributes: {
        email: {
          required: true
        }
      },
      passwordPolicy: {
        minLength: 8,
        // requireLowercase: true,
        // requireUppercase: true,
        // requireDigits: true,
        // requireSymbols: true
      },
      accountRecovery: AccountRecovery.EMAIL_ONLY,
      userVerification: {
        emailStyle: VerificationEmailStyle.LINK,
        emailSubject: 'Verify your new account',
        emailBody: 'Thanks for signing! Please click here to verify your account: {##Verify Email##}'
      }
    });

    this.userPoolClient = this.userPool.addClient('CognitoClient', {
      authFlows: {
        userSrp: true
      },
      disableOAuth: true
    });

    this.userPool.addTrigger(UserPoolOperation.POST_CONFIRMATION, new Function(this, 'SignUpConfirmedEventProxy', 
      {
        runtime: Runtime.RUBY_3_2,
        handler: 'main.handler',
        code: Code.fromAsset(`${__dirname}/lambda/post_signup`, {exclude: ["**", "!main.rb"]}),
        initialPolicy: [props.event_bridge.putEventsPolicy],
        environment: {
          EVENT_BUS_NAME: props.event_bridge.gameplayEventsBus.eventBusName
        }
      }
    ));

    new StringParameter(this, 'CognitoUserPoolId', {
      parameterName: `/${Stack.of(this).stackName}/cognito/user-pool-id`,
      stringValue: this.userPool.userPoolId
    });

    new StringParameter(this, 'CognitoUserPoolClientId', {
      parameterName: `/${Stack.of(this).stackName}/cognito/user-pool-client-id`,
      stringValue: this.userPoolClient.userPoolClientId
    });
  }
}
