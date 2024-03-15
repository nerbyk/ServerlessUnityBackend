import { Construct } from 'constructs';
import { UserPool, UserPoolClient, UserPoolOperation, AccountRecovery, VerificationEmailStyle, UserPoolDomain } from 'aws-cdk-lib/aws-cognito';
import { StringParameter } from 'aws-cdk-lib/aws-ssm';
import { Code, Function, Runtime } from 'aws-cdk-lib/aws-lambda';
import { Stack } from 'aws-cdk-lib';
import { PolicyStatement } from 'aws-cdk-lib/aws-iam';
import { EventBusik } from '../event_bridge/infrastructure';

type CognitoAuthProps = {
  gameplayEB: EventBusik;
};

export class CognitoAuth extends Construct {
  readonly userPool: UserPool;
  readonly userPoolName: string;
  readonly userPoolDomain: UserPoolDomain;
  readonly userPoolClient: UserPoolClient;

  constructor(scope: Construct, id: string, props: CognitoAuthProps) {
    super(scope, id);

    const { gameplayEB } = props;

    this.userPool =  new UserPool(this, `CognitoUserPool`, {
      userPoolName: Stack.of(this).stackName + 'UserPool',
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

    this.userPoolDomain = this.userPool.addDomain('CognitoDomain', {
      cognitoDomain: {
        domainPrefix: 'gameplay'
      }
    });

    this.userPool.addTrigger(UserPoolOperation.POST_CONFIRMATION, new Function(this, 'SignUpConfirmedEventProxy',
      {
        runtime: Runtime.RUBY_3_2,
        handler: 'main.handler',
        code: Code.fromAsset(`${__dirname}/lambda/post_signup`, {exclude: ["**", "!main.rb"]}),
        initialPolicy: [gameplayEB.putEventsPolicy],
        environment: {
          EVENT_BUS_NAME: gameplayEB.gameplayEventsBus.eventBusName
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
