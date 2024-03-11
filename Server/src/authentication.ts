
import { ParsedQs } from 'qs';
import { AccessUserDataDynamoDB } from "./access-dynamodb";
import { AttributeValue } from '@aws-sdk/client-dynamodb';
import { request } from 'http';

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

// Get all players status 

export async function handleScanUsersStatus(): Promise<Record<string, AttributeValue>[] | undefined> {
    try {
        return await accessDB.scanPlayerStatus()
    } catch(e) {
        throw new Error(`DEBUG: Error in handleGetUserData ${e}`)
    }
}

// Set player status
export async function handleSetUserStatus(requestBody: UserStatus) {
    try {
        
        // Set the user name to whatever is provided by the client
        await accessDB.updateItemInTable("User-Data", "User-ID", requestBody.id, "Player-Status", requestBody.status)

    } catch(e) {
        throw new Error(`DEBUG: Error in handleSetUserData ${e}`)
    }
}

interface UserStatus {
    id: string;
    status: string;
}

interface UserData {
    id: string;
    name: string;
}
