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
    getPhotoKey(userID) {
        return __awaiter(this, void 0, void 0, function* () {
            const input = {
                "Key": {
                    "User-ID": {
                        "S": `${userID}`
                    }
                },
                "TableName": "User-Data",
                "AttributesToGet": ["User-Photo-Key"]
            };
            const command = new client_dynamodb_1.GetItemCommand(input);
            try {
                const results = yield this.client.send(command);
                // Accessing the 'User-Photo-Key' attribute in the Item object
                if (results.Item && results.Item["User-Photo-Key"] && results.Item["User-Photo-Key"].S) {
                    const userPhotoKey = results.Item["User-Photo-Key"].S;
                    console.log("User Photo Key:", userPhotoKey);
                    return userPhotoKey;
                }
                else {
                    console.log("User Photo Key not found.");
                    return null;
                }
            }
            catch (err) {
                console.error(err);
            }
        });
    }
    putPhotoKeyItem(userID, userPhotoKey) {
        return __awaiter(this, void 0, void 0, function* () {
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
                const command = new client_dynamodb_1.PutItemCommand(input);
                yield this.client.send(command);
            }
            catch (err) {
                console.error(err);
            }
        });
    }
}
exports.AccessUserDataDynamoDB = AccessUserDataDynamoDB;
module.exports = { AccessUserDataDynamoDB };
