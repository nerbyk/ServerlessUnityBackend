import { RemovalPolicy, Stack } from 'aws-cdk-lib';
import { WebSocketApi, WebSocketStage } from 'aws-cdk-lib/aws-apigatewayv2';
import { WebSocketLambdaAuthorizer } from 'aws-cdk-lib/aws-apigatewayv2-authorizers';
import { WebSocketLambdaIntegration } from 'aws-cdk-lib/aws-apigatewayv2-integrations';
import { AttributeType, BillingMode, Table } from 'aws-cdk-lib/aws-dynamodb';
import { Code, Function, Runtime } from 'aws-cdk-lib/aws-lambda';
import { NodejsFunction } from 'aws-cdk-lib/aws-lambda-nodejs';
import { Construct } from 'constructs';
import path = require('path');
import { EventBusik } from '../event_bridge/infrastructure';
import { CognitoAuth } from '../auth/infrastructure';

interface WebSocketApiProps {
  auth: CognitoAuth;
  eventBridge: EventBusik;
}

export class WebhookApi extends Construct {
  readonly api: WebSocketApi;

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

    const authorizerLambda = new NodejsFunction(this, "AuthorizerLambda", {
      runtime: Runtime.NODEJS_LATEST,
      entry: path.join(__dirname, "/lambda/websocket/authorizer/index.ts"),
      environment: {
        COGNITO_POOL_ID: userPool.userPoolId,
        COGNITO_USER_POOL_CLIENT_ID: userPoolClient.userPoolClientId
      },
      bundling: {
        externalModules: [],
        nodeModules: ["aws-jwt-verify"]
      },
      handler: "handler"
    });

    const dispatcherLambda = new Function(this, "DispatchLambda", {
      runtime: Runtime.RUBY_3_2,
      code:Code.fromAsset(`${__dirname}/lambda/websocket/dispatch`, {exclude: ["Makefile", ".bundle"]}),
      handler: "main.Dispatcher.handler",
      environment: {
        CONNECTION_TABLE_NAME: connectionTable.tableName,
        EVENT_BUS_NAME: gameplayEventsBus.eventBusName
      },
      initialPolicy: [eventBridge.putEventsPolicy],
    });
    connectionTable.grantReadWriteData(dispatcherLambda);
    gameplayEventsBus.grantPutEventsTo(dispatcherLambda);

    const authorizer = new WebSocketLambdaAuthorizer('Authorizer', authorizerLambda);
    const integration = new WebSocketLambdaIntegration("Integration", dispatcherLambda);

    const webSocketApi = new WebSocketApi(this, 'Api', {
      apiName: Stack.of(this).stackName + 'WebSocketApi',
      connectRouteOptions: { integration, authorizer },
      defaultRouteOptions: { integration },
      disconnectRouteOptions: { integration },
    })

    new WebSocketStage(this, 'Stage', {
      stageName: Stack.of(this).stackName + 'WebSocketStage',
      webSocketApi,
    });

    this.api = webSocketApi;
  }
}
