import { AttributeValue, DynamoDBClient, GetItemCommand, PutItemCommand, UpdateItemCommand } from "@aws-sdk/client-dynamodb";

export class AccessUserDataDynamoDB {

	client: DynamoDBClient

	constructor(region: string) {
		this.client = new DynamoDBClient({ region: region });
	}

	async getUserData(userID: string): Promise<Record<string, AttributeValue> | undefined> {

		const input = {
			"Key": {
				"User-ID": {
					"S": `${userID}`
				}
			},
			"TableName": "User-Data",
		};

		const command = new GetItemCommand(input);

		try {
			const results = await this.client.send(command);

			if (results.Item) {
				return results.Item;
			} else {
				return undefined;
			}
		} catch (e) {
			throw new Error(`DEBUG: Error in getUserData ${e}`);
		}
	}

	async putKeyItemInUserData(userID: string, key: string, value: string) {

		const input = {
			"Item": {
				"User-ID": {
					"S": `${userID}`
				},
				[key]: {
					"S": `${value}`
				}
			},
			"TableName": "User-Data"
		};

		const command = new PutItemCommand(input);

		try {
			await this.client.send(command);
		} catch (e) {
			throw new Error(`DEBUG: Error in putKeyItemInUserData ${e}`);
		}
	}

	async updateItemInUserData(userID: string, key: string, value: string) {

		const params = {
			TableName: "User-Data",
			Key: {
				"User-ID": {
					"S": `${userID}`
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
			await this.client.send(command);
		} catch (e) {
			throw new Error(`DEBUG: Error in updateItemInUserData ${e}`);
		}
	}
}