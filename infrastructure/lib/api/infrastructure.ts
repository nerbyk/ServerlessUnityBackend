import { Duration, RemovalPolicy, Stack } from 'aws-cdk-lib';
import { WebSocketApi, WebSocketStage } from 'aws-cdk-lib/aws-apigatewayv2';
import { WebSocketLambdaAuthorizer } from 'aws-cdk-lib/aws-apigatewayv2-authorizers';
import { WebSocketLambdaIntegration } from 'aws-cdk-lib/aws-apigatewayv2-integrations';
import { AttributeType, BillingMode, Table } from 'aws-cdk-lib/aws-dynamodb';
import { Code, Function, Runtime } from 'aws-cdk-lib/aws-lambda';
import * as openapix from '@alma-cdk/openapix';
import { Construct } from 'constructs';
import path = require('path');
import { EventBusik } from '../event_bridge/infrastructure';
import { CognitoAuth } from '../auth/infrastructure';
import { RetentionDays } from 'aws-cdk-lib/aws-logs';
import { IdentitySource } from 'aws-cdk-lib/aws-apigateway';

type RestApiFunctions = {
  getUserData: Function
}

interface WebSocketApiProps {
  auth: CognitoAuth;
  eventBridge: EventBusik;
  restApiFunctions: RestApiFunctions;
}

export class WebhookAndRestApi extends Construct {
  readonly api: WebSocketApi;
  readonly stage: WebSocketStage;

  constructor(scope: Construct, id: string, props: WebSocketApiProps) {
    super(scope, id);

    const { auth, eventBridge } = props;
    const { userPool, userPoolClient } = auth;
    const { gameplayEventsBus } = eventBridge;

    const connectionTable = new Table(this, "ConnectionIdTable", {
      partitionKey: { name: "connectionId", type: AttributeType.STRING },
      timeToLiveAttribute: "removedAt",
      billingMode: BillingMode.PAY_PER_REQUEST,
      removalPolicy: RemovalPolicy.DESTROY,
    });

    connectionTable.addGlobalSecondaryIndex({
      partitionKey: { name: "userId", type: AttributeType.STRING },
      indexName: "userIdIndex",
    });

    const authorizerLambda = new Function(this, "AuthorizerLambda", {
      runtime: Runtime.RUBY_3_2,
      handler: "main.handler",
      code: Code.fromAsset(`${__dirname}/lambda/authorizer`, {exclude: [".bundle", "Makefile"]}),
      environment: {
        COGNITO_USER_POOL_ID: userPool.userPoolId,
      },
      logRetention: RetentionDays.ONE_DAY,
    });

    const dispatcherLambda = new Function(this, "DispatchLambda", {
      runtime: Runtime.RUBY_3_2,
      code:Code.fromAsset(`${__dirname}/lambda/dispatch`, {exclude: [".bundle", "Makefile", "test"]}),
      handler: "main.Dispatcher.handler",
      environment: {
        CONNECTION_TABLE_NAME: connectionTable.tableName,
        EVENT_BUS_NAME: gameplayEventsBus.eventBusName
      },
      initialPolicy: [eventBridge.putEventsPolicy],
      logRetention: RetentionDays.ONE_DAY,
    });
    connectionTable.grantReadWriteData(dispatcherLambda);
    gameplayEventsBus.grantPutEventsTo(dispatcherLambda);

    const authorizer = new WebSocketLambdaAuthorizer('Authorizer', authorizerLambda);
    const integration = () => new WebSocketLambdaIntegration("Integration", dispatcherLambda);

    const webSocketApi = new WebSocketApi(this, 'Api', {
      apiName: Stack.of(this).stackName + 'WebSocketApi',
      connectRouteOptions: { integration: integration(), authorizer },
      defaultRouteOptions: { integration: integration() },
      disconnectRouteOptions: { integration: integration() },
    })

    this.stage = new WebSocketStage(this, 'Stage', {
      stageName: Stack.of(this).stackName + 'WebSocketStage',
      webSocketApi,
      autoDeploy: true
    });

    this.api = webSocketApi;

    this.buildRestApiOpenapix(props.restApiFunctions, authorizerLambda);
  }

  buildRestApiOpenapix(restApiFunctions: RestApiFunctions, authorizerFunction: Function) {
    new openapix.Api(this, 'RestApi', {
      source: "../gameplay_backend/open_api_schema.yml",
      paths: {
        "/user_data": {
          get: new openapix.LambdaIntegration(this, restApiFunctions.getUserData)
        }
      },
      authorizers: [
        new openapix.LambdaAuthorizer(this, 'cognito', {
          fn: authorizerFunction,
          identitySource: IdentitySource.header('Authorization'),
          type: 'request',
          authType: 'custom',
          resultsCacheTtl: Duration.minutes(5),
        }),
      ]
    })
  }
}
