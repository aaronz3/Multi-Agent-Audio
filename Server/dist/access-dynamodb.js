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
    getData(userID) {
        return __awaiter(this, void 0, void 0, function* () {
            const input = {
                "Key": {
                    "User-ID": {
                        "S": `${userID}`
                    }
                },
                "TableName": "User-Data",
            };
            const command = new client_dynamodb_1.GetItemCommand(input);
            try {
                const results = yield this.client.send(command);
                if (results.Item) {
                    return results.Item;
                }
                else {
                    return undefined;
                }
            }
            catch (e) {
                throw new Error(`DEBUG: Error in getData ${e}`);
            }
        });
    }
    putKeyItemInUserData(userID, itemkey, keyvalue) {
        return __awaiter(this, void 0, void 0, function* () {
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
            const command = new client_dynamodb_1.PutItemCommand(input);
            try {
                yield this.client.send(command);
            }
            catch (e) {
                throw new Error(`DEBUG: Error in putKeyItemInUserData ${e}`);
            }
        });
    }
}
exports.AccessUserDataDynamoDB = AccessUserDataDynamoDB;
