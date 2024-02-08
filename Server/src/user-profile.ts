import { AccessS3 } from "./access-s3";
import { AccessUserDataDynamoDB } from "./access-dynamodb";
import { v4 as uuidv4 } from 'uuid';

require("dotenv").config();

const s3BucketRegion = process.env.S3_BUCKET_REGION;
const s3BucketName = process.env.S3_BUCKET_NAME;
const dynamodbBucketRegion = process.env.DYNAMODB_BUCKET_REGION;

const accessS3 = new AccessS3(s3BucketRegion);
const accessUserDataDynamoDB = new AccessUserDataDynamoDB(dynamodbBucketRegion);

function generateUniqueKey(userID) {
	const uuid = uuidv4(); // Generates a unique UUID
	// Once you have authentication set up you can append the userid to the front of the UUID to almost guarantee that there will be no duplication.
	const uniqueKey = `${userID}-${uuid}`;
	return uniqueKey;
}

export function handleUploadProfilePhoto(req) {

	const userUUID = req.body["User-UUID"];
	const profilePhotoUniqueKey = generateUniqueKey(userUUID);
	
	console.log(`Photo key is: ${profilePhotoUniqueKey}`);

	// Check the database to see if their already exists a profile photo key. If so, use that key to delete the previous s3 object.

	// Put object in s3 bucket 
	accessS3.putObject(req.file.buffer, s3BucketName, profilePhotoUniqueKey);   
	
	// Update database with the generated key
	accessUserDataDynamoDB.putPhotoKeyItem(userUUID, profilePhotoUniqueKey);

}

export async function handleDownloadProfilePhoto(req) {
	
	const userUUIDs = req.query["User-UUIDs"];
	
	// Split the string by commas to get an array of user UUIDs
	const uuidArray = userUUIDs.split(",");

	let photoUrls = [];

	for (const uuid of uuidArray) {
		
		// Get the photo key from the UUIDs of the users with profile photo
		const photoKey = await accessUserDataDynamoDB.getPhotoKey(uuid);

		// Access s3 to send back the photo
		photoUrls.push(await accessS3.getObjectUrl(s3BucketName, `${photoKey}`));
	}
	
	return photoUrls;
}

module.exports = { handleUploadProfilePhoto, handleDownloadProfilePhoto };