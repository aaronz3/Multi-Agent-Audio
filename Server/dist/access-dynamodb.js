"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AccessUserDataDynamoDB = void 0;
const client_dynamodb_1 = require("@aws-sdk/client-dynamodb");
class AccessUserDataDynamoDB {
    constructor(region) {
        this.client = new client_dynamodb_1.DynamoDBClient({ region: region });
    }
    getDataInTable(tableName, partitionKey, partitionValue) {
        return __awaiter(this, void 0, void 0, function* () {
            const input = {
                "Key": {
                    [partitionKey]: {
                        "S": `${partitionValue}`
                    }
                },
                "TableName": tableName,
            };
            const command = new client_dynamodb_1.GetItemCommand(input);
            try {
                const results = yield this.client.send(command);
                console.log(`Get in ${tableName}`);
                if (results.Item) {
                    return results.Item;
                }
                else {
                    return undefined;
                }
            }
            catch (e) {
                throw new Error(`DEBUG: Error in getDataInTable ${e}`);
            }
        });
    }
    putItemInTable(tableName, partitionKey, partitionValue, item) {
        return __awaiter(this, void 0, void 0, function* () {
            // const input = {
            // 	"Item": {
            // 		[partitionKey]: {
            // 			"S": partitionValue
            // 		},
            // 		[key]: {
            // 			"S": value
            // 		}
            // 	},
            // 	"TableName": tableName
            // };
            // Prepare the item for DynamoDB format
            const dynamoItem = {};
            // Set the partition key's value 
            dynamoItem[partitionKey] = { "S": partitionValue };
            // Set the other values
            for (const key in item) {
                dynamoItem[key] = item[key]; // Assuming all values are strings for simplicity
            }
            const input = {
                "TableName": tableName,
                "Item": dynamoItem
            };
            const command = new client_dynamodb_1.PutItemCommand(input);
            try {
                yield this.client.send(command).then(() => { console.log(`Putted in ${tableName}`); });
            }
            catch (e) {
                throw new Error(`DEBUG: Error in putItemInTable ${e}`);
            }
        });
    }
    putItemsInTable(tableName, partitionKey, partitionValue, key, values) {
        return __awaiter(this, void 0, void 0, function* () {
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
            const command = new client_dynamodb_1.PutItemCommand(input);
            try {
                yield this.client.send(command).then(() => { console.log(`Putted ${tableName}'s ${key} to ${values}`); });
            }
            catch (e) {
                throw new Error(`DEBUG: Error in putItemsInTable ${e}`);
            }
        });
    }
    updateItemInTable(tableName, partitionKey, partitionValue, key, value) {
        return __awaiter(this, void 0, void 0, function* () {
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
            const command = new client_dynamodb_1.UpdateItemCommand(params);
            try {
                yield this.client.send(command).then(() => { console.log(`Updated ${tableName}'s ${key} to ${value}`); });
            }
            catch (e) {
                throw new Error(`DEBUG: Error in updateItemInTable ${e}`);
            }
        });
    }
    updateItemsInTable(tableName, partitionKey, partitionValue, key, values) {
        return __awaiter(this, void 0, void 0, function* () {
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
            const command = new client_dynamodb_1.UpdateItemCommand(params);
            try {
                yield this.client.send(command).then(() => { console.log(`Added ${tableName}'s ${key} to ${values}`); });
            }
            catch (e) {
                throw new Error(`DEBUG: Error in updateItemsInTable ${e}`);
            }
        });
    }
    deleteItemInTable(tableName, partitionKey, partitionValue) {
        return __awaiter(this, void 0, void 0, function* () {
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
                const command = new client_dynamodb_1.DeleteItemCommand(params);
                // Send the DeleteItemCommand using the DynamoDB client
                yield this.client.send(command).then(() => { console.log(`Deleted ${tableName}'s entry ${partitionValue}`); });
            }
            catch (e) {
                throw new Error(`DEBUG: Error in deleteItemInTable ${e}`);
            }
        });
    }
    deleteItemInColumnInTable(tableName, partitionKey, partitionValue, key) {
        return __awaiter(this, void 0, void 0, function* () {
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
                const command = new client_dynamodb_1.UpdateItemCommand(params);
                // Send the DeleteItemCommand using the DynamoDB client
                yield this.client.send(command).then(() => { console.log(`Deleted ${tableName}'s cell ${key}`); });
            }
            catch (e) {
                throw new Error(`DEBUG: Error in deleteItemInTable ${e}`);
            }
        });
    }
    deleteItemsInSSInTable(tableName, partitionKey, partitionValue, key, values) {
        return __awaiter(this, void 0, void 0, function* () {
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
            const command = new client_dynamodb_1.UpdateItemCommand(params);
            try {
                yield this.client.send(command).then(() => { console.log(`Deleted ${tableName}'s ${key} to ${values}`); });
            }
            catch (e) {
                throw new Error(`DEBUG: Error in updateItemsInTable ${e}`);
            }
        });
    }
}
exports.AccessUserDataDynamoDB = AccessUserDataDynamoDB;
