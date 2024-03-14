import { aws_apigatewayv2_integrations } from 'aws-cdk-lib';
import * as apigateway from 'aws-cdk-lib/aws-apigatewayv2';
import { UserPool } from 'aws-cdk-lib/aws-cognito';
import { Rule } from 'aws-cdk-lib/aws-events';
import { Construct } from 'constructs';

interface WebSocketApiProps {
  userPool: UserPool;
  eventBridgeRule: Rule;
}


export class WebSocketApi extends Construct {
  readonly api: apigateway.WebSocketApi;

  constructor(scope: Construct, id: string, props: WebSocketApiProps) {
    super(scope, id);
    
    this.api = new apigateway.WebSocketApi(this, 'Api')

  
  }
}

