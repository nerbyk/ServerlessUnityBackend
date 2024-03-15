import { Table, AttributeType, ProjectionType } from 'aws-cdk-lib/aws-dynamodb';
import { Effect, PolicyStatement } from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';

type GameplayDDBTables = {
  users: Table;
  entitiesReceipts: Table;
  items: Table;
}

type GameplayDDBPolicies = {
  listTables: PolicyStatement;
}

export class GameplayDDB extends Construct {
  readonly tables: GameplayDDBTables
  readonly policies: GameplayDDBPolicies

  constructor(scope: Construct, id: string) {
    super(scope, id);

    this.tables = this.setup_tables();
    this.policies = this.setup_policies();
  }

  private setup_tables(): GameplayDDBTables {
    const users = new Table(this, 'Users', {
      partitionKey: { name: 'user_id', type: AttributeType.STRING },
    });

    const entitiesReceipts = new Table(this, 'Receipts', {
      partitionKey: { name: 'guid', type: AttributeType.STRING },
      sortKey: { name: 'entity_guid', type: AttributeType.STRING },
    });

    const items = new Table(this, 'UserItems', {
      partitionKey: { name: 'guid', type: AttributeType.STRING },
      sortKey: { name: 'user_id', type: AttributeType.STRING },
    });

    return { users, entitiesReceipts, items }
  }

  private setup_policies(): GameplayDDBPolicies {
    const listTables = new PolicyStatement({
        effect: Effect.ALLOW,
        actions: ['dynamodb:ListTables'],
        resources: Object.values(this.tables).map(its => its.tableArn)
      }
    )

    return { listTables }
  };
}