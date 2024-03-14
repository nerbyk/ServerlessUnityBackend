import { Table, AttributeType, ProjectionType } from 'aws-cdk-lib/aws-dynamodb';
import { Construct } from 'constructs';

export class GameplayDDB extends Construct {
  readonly gameUsersTable: Table
  readonly gameEntitiesTable: Table;
  readonly gameEntitiesReceiptsTable: Table;
  readonly gameItemsTable: Table;

  constructor(scope: Construct, id: string) {
    super(scope, id);

    this.gameUsersTable = new Table(this, 'GameUsers', {
      partitionKey: { name: 'user_id', type: AttributeType.STRING },
    });

    this.gameEntitiesReceiptsTable = new Table(this, 'Receipts', {
      partitionKey: { name: 'guid', type: AttributeType.STRING },
      sortKey: { name: 'entity_guid', type: AttributeType.STRING },
    });

    this.gameItemsTable = new Table(this, 'UserItems', {
      partitionKey: { name: 'guid', type: AttributeType.STRING },
      sortKey: { name: 'user_id', type: AttributeType.STRING },
    });
  }
}
