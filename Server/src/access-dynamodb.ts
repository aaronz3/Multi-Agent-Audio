import { AttributeValue, DynamoDBClient, GetItemCommand, ScanCommand, PutItemCommand, UpdateItemCommand, DeleteItemCommand } from "@aws-sdk/client-dynamodb";

// Define a type that describes the structure of your object
type DynamoItem = {
	[key: string]: { "S": string } | { "SS": string[] }; // Add other types as needed
};

export class AccessUserDataDynamoDB {

	client: DynamoDBClient

	constructor(region: string) {
		this.client = new DynamoDBClient({ region: region });
	}

	async getDataInTable(tableName: string, partitionKey: string, partitionValue: string): Promise<Record<string, AttributeValue> | undefined> {

		const input = {
			Key: {
				[partitionKey]: {
					"S": `${partitionValue}`
				}
			},
			TableName: tableName,
		};

		const command = new GetItemCommand(input);

		try {
			const results = await this.client.send(command);
			return results.Item
		} catch (e) {
			throw new Error(`DEBUG: Error in getDataInTable ${e}`);
		}
	}

	async scanPlayerStatus(): Promise<Record<string, AttributeValue>[] | undefined> {
		// Set up the scan command with a filter expression
		const params = {
			TableName: "User-Data",
			ProjectionExpression: "#userID, #playerStatus",
			FilterExpression: "attribute_exists(#playerStatus)",
			ExpressionAttributeNames: {
				"#userID": "User-ID",
				"#playerStatus": "Player-Status"
			}
		};

		const command = new ScanCommand(params);

		try {
			
			const results = await this.client.send(command);
						
			if (results.Items) {
				return results.Items;
			} else {
				return undefined;
			}
		} catch (e) {
			throw new Error(`DEBUG: Error in scanPlayerStatus ${e}`);
		}
	}

	async putItemInTable(tableName: string, partitionKey: string, partitionValue: string, item: DynamoItem) {

		// Prepare the item for DynamoDB format
		const dynamoItem: DynamoItem = {};

		// Set the partition key's value 
		dynamoItem[partitionKey] = { "S": partitionValue }

		// Set the other values
		for (const key in item) {
			dynamoItem[key] = item[key]; // Assuming all values are strings for simplicity
		}

		const input = {
			"TableName": tableName,
			"Item": dynamoItem
		};

		const command = new PutItemCommand(input);

		try {
			await this.client.send(command).then(() => { console.log(`Putted in ${tableName}`) });
		} catch (e) {
			throw new Error(`DEBUG: Error in putItemInTable ${e}`);
		}
	}

	async putItemsInTable(tableName: string, partitionKey: string, partitionValue: string, key: string, values: [string]) {

		const input = {
			"Item": {
				[partitionKey]: {
					"S": partitionValue
				},
				[key]: {
					"SS": values
				}
			},
			"TableName": tableName
		};

		const command = new PutItemCommand(input);

		try {
			await this.client.send(command).then(() => { console.log(`Putted ${tableName}'s ${key} to ${values}`) });
		} catch (e) {
			throw new Error(`DEBUG: Error in putItemsInTable ${e}`);
		}
	}

	async updateItemInTable(tableName: string, partitionKey: string, partitionValue: string, key: string, value: string) {

		const params = {
			TableName: tableName,
			Key: {
				[partitionKey]: {
					"S": partitionValue
				}
			},
			UpdateExpression: "SET #key = :value",
			ExpressionAttributeNames: {
				"#key": key
			},
			ExpressionAttributeValues: {
				":value": {
					S: value
				}
			}

		};

		const command = new UpdateItemCommand(params);

		try {
			await this.client.send(command).then(() => { console.log(`Updated ${tableName}'s ${key} to ${value}`) })
		} catch (e) {
			throw new Error(`DEBUG: Error in updateItemInTable ${e}`);
		}
	}

	async updateItemsInTable(tableName: string, partitionKey: string, partitionValue: string, key: string, values: [string]) {

		const params = {
			TableName: tableName,
			Key: {
				[partitionKey]: {
					"S": partitionValue
				}
			},
			UpdateExpression: "ADD #key :value",
			ExpressionAttributeNames: {
				"#key": key
			},
			ExpressionAttributeValues: {
				":value": {
					SS: values
				}
			}
		};

		const command = new UpdateItemCommand(params);

		try {
			await this.client.send(command).then(() => { console.log(`Added ${tableName}'s ${key} to ${values}`) });
		} catch (e) {
			throw new Error(`DEBUG: Error in updateItemsInTable ${e}`);
		}
	}

	async deleteItemInTable(tableName: string, partitionKey: string, partitionValue: string) {
		// Set the parameters
		const params = {
			TableName: tableName,
			Key: {
				[partitionKey]: {
					"S": partitionValue
				}
			}
		};

		try {
			// Create a DeleteItemCommand with the specified parameters
			const command = new DeleteItemCommand(params);

			// Send the DeleteItemCommand using the DynamoDB client
			await this.client.send(command).then(() => { console.log(`Deleted ${tableName}'s entire row ${partitionValue}`) });

		} catch (e) {
			throw new Error(`DEBUG: Error in deleteItemInTable ${e}`);
		}
	}

	async deleteItemInColumnInTable(tableName: string, partitionKey: string, partitionValue: string, key: string) {
		// Set the parameters
		const params = {
			TableName: tableName,
			Key: {
				[partitionKey]: {
					S: partitionValue
				}
			},
			UpdateExpression: "REMOVE #key",
			ExpressionAttributeNames: {
				"#key": key
			}
		};

		try {
			// Create a DeleteItemCommand with the specified parameters
			const command = new UpdateItemCommand(params);

			// Send the DeleteItemCommand using the DynamoDB client
			await this.client.send(command).then(() => { console.log(`Deleted ${tableName}'s cell ${key}`) });

		} catch (e) {
			throw new Error(`DEBUG: Error in deleteItemInTable ${e}`);
		}
	}

	async deleteItemsInSSInTable(tableName: string, partitionKey: string, partitionValue: string, key: string, values: [string]) {

		const params = {
			TableName: tableName,
			Key: {
				[partitionKey]: {
					"S": partitionValue
				}
			},
			UpdateExpression: "DELETE #key :value",
			ExpressionAttributeNames: {
				"#key": key
			},
			ExpressionAttributeValues: {
				":value": {
					SS: values
				}
			}

		};

		const command = new UpdateItemCommand(params);

		try {
			await this.client.send(command).then(() => { console.log(`Deleted ${tableName}'s ${key} to ${values}`) });
		} catch (e) {
			throw new Error(`DEBUG: Error in updateItemsInTable ${e}`);
		}
	}
}