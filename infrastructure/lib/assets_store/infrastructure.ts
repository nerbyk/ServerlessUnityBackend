import * as cdk from 'aws-cdk-lib';
import {Bucket } from 'aws-cdk-lib/aws-s3';
import { BucketDeployment, Source } from 'aws-cdk-lib/aws-s3-deployment';
import { Construct } from 'constructs';

export class GameplayStaticsStore extends Construct {
  readonly staticsStore: Bucket;

  constructor(scope: Construct, id: string) {
    super(scope, id);

    this.staticsStore = new Bucket(this, 'GameplayStaticsBucket', {
      versioned: true, // Enable versioning for the bucket
      bucketName: cdk.Stack.of(this).stackName.toLowerCase() + '-statics',
      removalPolicy: cdk.RemovalPolicy.DESTROY
    });

    new BucketDeployment(this, "DeployGameplayStatics", {
      destinationBucket: this.staticsStore,
      sources: [
        Source.asset('vendor/gameplay_backend/assets'),
      ],
    })

    new cdk.CfnOutput(this, 'StaticsBucketName', {
      value: this.staticsStore.bucketName,
    })
  }
}
