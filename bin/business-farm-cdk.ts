#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { BusinessFarmCdkStack } from '../lib/business-farm-cdk-stack';

const app = new cdk.App();
new BusinessFarmCdkStack(app, 'BusinessFarmCdkStack');
