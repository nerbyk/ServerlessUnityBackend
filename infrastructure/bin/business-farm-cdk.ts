#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { BusinessFarmCdkStack } from '../lib/business-farm-cdk-stack';
import { getConfig } from '../lib/config';


const app     = new cdk.App();
const config  = getConfig(app.node.tryGetContext('env'));
new BusinessFarmCdkStack(app, config.APP_NAME);
