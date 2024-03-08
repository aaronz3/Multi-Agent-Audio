
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
        return await accessDB.getDataInTable("User-Data", "User-ID", requestQuery.uuid)
    } catch(e) {
        throw new Error(`DEBUG: Error in handleGetUserData ${e}`)
    }
}

// Set the user data 
export async function handleSetUserData(requestBody: UserData) {
    try {
        
        // Format of the data to update the database
        const userNameItem = {
            "User-Name" : { "S" : requestBody.name }
        }

        // Set the user name to whatever is provided by the client
        await accessDB.putItemInTable("User-Data", "User-ID", requestBody.id, userNameItem)

    } catch(e) {
        throw new Error(`DEBUG: Error in handleSetUserData ${e}`)
    }
}

interface UserData {
    name: string;
    id: string;
}
