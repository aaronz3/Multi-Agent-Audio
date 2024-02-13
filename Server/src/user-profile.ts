import { AccessS3 } from "./access-s3";
import { AccessUserDataDynamoDB } from "./access-dynamodb";
import { v4 as uuidv4 } from 'uuid';
import { type Request } from 'express';

require("dotenv").config({ path: '../.env' });

const s3BucketRegion: string = process.env.S3_BUCKET_REGION!;
const s3BucketName: string = process.env.S3_BUCKET_NAME!;
const dynamodbBucketRegion: string = process.env.DYNAMODB_BUCKET_REGION!;

const accessS3 = new AccessS3(s3BucketRegion);
const accessUserDataDynamoDB = new AccessUserDataDynamoDB(dynamodbBucketRegion);

function generateUniqueKey(userID: string): string {
	const uuid: string = uuidv4(); // Generates a unique UUID
	// Once you have authentication set up you can append the userid to the front of the UUID to almost guarantee that there will be no duplication.
	const uniqueKey = `${userID}-${uuid}`;
	return uniqueKey;
}

export function handleUploadProfilePhoto(req: Request) {

	const userUUID: string = req.body["User-UUID"];
	const profilePhotoUniqueKey = generateUniqueKey(userUUID);
	
	// Check the database to see if there already exists a profile photo key. If so, use that key to delete the previous s3 object.

	// Put object in s3 bucket 
	if (req.file) {
		accessS3.putObject(req.file.buffer.toString(), s3BucketName, profilePhotoUniqueKey);   
    } else {
        console.log("DEBUG: req.file does not exist")
    }

	// Update database with the generated key
	accessUserDataDynamoDB.putPhotoKeyItem(userUUID, profilePhotoUniqueKey);
}

export async function handleDownloadProfilePhoto(req: Request): Promise<string[]> {
	
	// Check if the request query is a string first. If not return an empty array
	if (typeof req.query["User-UUIDs"] !== "string") {
		console.log("DEBUG: Returned query is not an array");
		return [];
	}

	const userUUIDs: string = req.query["User-UUIDs"];
	
	// Split the string by commas to get an array of user UUIDs
	const uuidArray: string[] = userUUIDs.split(",");

	let photoUrls: string[] = [];

	for (const uuid of uuidArray) {
		
		// Get the photo key from the UUIDs of the users with profile photo
		const photoKey = await accessUserDataDynamoDB.getPhotoKey(uuid);

		// Access s3 to send back the photo
		photoUrls.push(await accessS3.getObjectUrl(s3BucketName, `${photoKey}`));
	}
	
	return photoUrls;
}