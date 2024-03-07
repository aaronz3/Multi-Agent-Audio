
import { ParsedQs } from 'qs';
import { AccessUserDataDynamoDB } from "./access-dynamodb";
import { AttributeValue } from '@aws-sdk/client-dynamodb';

require("dotenv").config({ path: '../.env' });
const databaseRegion = process.env.DYNAMODB_BUCKET_REGION!;

const accessDB = new AccessUserDataDynamoDB(databaseRegion)

// Get the user data
export async function handleGetUserData(requestQuery: ParsedQs): Promise<Record<string, AttributeValue> | undefined> {
    if (typeof requestQuery.uuid !== "string") {
        throw new Error("DEBUG: uuid is not of type string")
    }
    
    try {
        return await accessDB.getUserData(requestQuery.uuid)
    } catch(e) {
        throw new Error(`DEBUG: Error in handleGetUserData ${e}`)
    }
}

// Set the user data 
export async function handleSetUserData(requestBody: UserData) {
    try {
        // Set the user name to whatever is provided by the client
        await accessDB.putKeyItemInUserData(requestBody.id, "User-Name", requestBody.name)

    } catch(e) {
        throw new Error(`DEBUG: Error in handleSetUserData ${e}`)
    }
}

interface UserData {
    name: string;
    id: string;
}
