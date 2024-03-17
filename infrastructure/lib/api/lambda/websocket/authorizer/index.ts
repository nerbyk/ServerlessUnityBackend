import { PolicyDocument } from 'aws-lambda';
import { CognitoJwtVerifier } from "aws-jwt-verify";

const { COGNITO_USER_POOL_ID, COGNITO_USER_POOL_CLIENT_ID } = process.env;

class Lambda {
  public async handler(event:any, context: any): Promise<any> {
    const token = event.authorizationToken;

    try {
        const cognitoVerifier = CognitoJwtVerifier.create({
          userPoolId: COGNITO_USER_POOL_ID!,
          clientId: COGNITO_USER_POOL_CLIENT_ID!,
          tokenUse: "id",
        });

        const verifiedToken = await cognitoVerifier.verify(token);
        return this.generateAllow(verifiedToken["cognito:username"], event.methodArn);
      } catch (err: any) {
        return this.generateDeny('default', event.methodArn);
      }

    return this.generateDeny('default', event.methodArn);
  }

  generatePolicy(principalId: any, effect: any, resource: any) {
      const authResponse:any = {
          principalId
      };
      if (effect && resource) {
          const policyDocument: PolicyDocument = ({
            Version: '2012-10-17',
            Statement: []
          });

          const statementOne = {
            Action: 'execute-api:Invoke',
            Effect: effect,
            Resource: resource,
          };
          policyDocument.Statement[0] = statementOne;
          authResponse.policyDocument = policyDocument;
      }

      authResponse.context = {
        "customerId": principalId
      };
      return authResponse;
  }

  generateAllow(principalId: any, resource: any) {
      return this.generatePolicy(principalId, 'Allow', resource);
  }

  generateDeny(principalId:any, resource:any) {
      return this.generatePolicy(principalId, 'Deny', resource);
  }
}

export const handlerClass = new Lambda();
export const handler = handlerClass.handler;