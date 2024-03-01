import { AttributeValue, DynamoDBClient, GetItemCommand, PutItemCommand } from "@aws-sdk/client-dynamodb";

export class AccessUserDataDynamoDB {

	client: DynamoDBClient

	constructor(region: string) {
		this.client = new DynamoDBClient({ region: region });
	}

	async getData(userID: string): Promise<Record<string, AttributeValue> | undefined> {

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
			throw new Error(`DEBUG: Error in getData ${e}`);
		}
	}
    
	async putKeyItemInUserData(userID: string, itemkey: string, keyvalue: string) {
		
		const input = {
			"Item": {
				"User-ID": {
					"S": `${userID}`
				},
				[itemkey]: {
					"S": `${keyvalue}`
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
}