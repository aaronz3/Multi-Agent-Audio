const { DynamoDBClient, GetItemCommand, PutItemCommand } = require("@aws-sdk/client-dynamodb");

class AccessUserDataDynamoDB {
	constructor(region) {
		this.client = new DynamoDBClient({ region: region });

	}

	async getPhotoKey(userID) {
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
		try {
			const results = await this.client.send(command);
            
			// Accessing the 'User-Photo-Key' attribute in the Item object
			if (results.Item && results.Item["User-Photo-Key"] && results.Item["User-Photo-Key"].S) {
				const userPhotoKey = results.Item["User-Photo-Key"].S;
				console.log("User Photo Key:", userPhotoKey);
				return userPhotoKey; 
			} else {
				console.log("User Photo Key not found.");
				return null;
			}
		} catch (err) {
			console.error(err);
		}
	}
    
	async putPhotoKeyItem(userID, userPhotoKey) {
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
        
		try {
			const command = new PutItemCommand(input);
			await this.client.send(command);
		} catch (err) {
			console.error(err);
		}
	}    
}

module.exports = { AccessUserDataDynamoDB };

