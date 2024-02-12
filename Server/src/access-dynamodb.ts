import { DynamoDBClient, GetItemCommand, PutItemCommand } from "@aws-sdk/client-dynamodb";

export class AccessUserDataDynamoDB {

	client: DynamoDBClient

	constructor(region: string) {
		this.client = new DynamoDBClient({ region: region });
	}

	async getPhotoKey(userID: string): Promise<string> {

		const input = {
			"Key": {
				"User-ID": {
					"S": `${userID}`
				}
			},
			"TableName": "User-Data",
			"AttributesToGet": ["User-Photo-Key"]
		};

		const command = new GetItemCommand(input);
		const results = await this.client.send(command);

		// Accessing the 'User-Photo-Key' attribute in the Item object
		if (results.Item && results.Item["User-Photo-Key"] && results.Item["User-Photo-Key"].S) {
			const userPhotoKey = results.Item["User-Photo-Key"].S;
			console.log("User Photo Key:", userPhotoKey);
			return userPhotoKey; 
		
		} else {
			console.log("DEBUG: User Photo Key not found.")
			return "";
		}
	}
    
	async putPhotoKeyItem(userID: string, userPhotoKey: string) {
		const input = {
			"Item": {
				"User-ID": {
					"S": `${userID}`
				},
				"User-Photo-Key": {
					"S": `${userPhotoKey}`
				}
			},
			"TableName": "User-Data"
		};
        
		const command = new PutItemCommand(input);
		await this.client.send(command);
	}    
}

