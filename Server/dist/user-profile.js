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
exports.handleDownloadProfilePhoto = exports.handleUploadProfilePhoto = void 0;
const access_s3_1 = require("./access-s3");
const access_dynamodb_1 = require("./access-dynamodb");
const uuid_1 = require("uuid");
require("dotenv").config();
const s3BucketRegion = process.env.S3_BUCKET_REGION;
const s3BucketName = process.env.S3_BUCKET_NAME;
const dynamodbBucketRegion = process.env.DYNAMODB_BUCKET_REGION;
const accessS3 = new access_s3_1.AccessS3(s3BucketRegion);
const accessUserDataDynamoDB = new access_dynamodb_1.AccessUserDataDynamoDB(dynamodbBucketRegion);
function generateUniqueKey(userID) {
    const uuid = (0, uuid_1.v4)(); // Generates a unique UUID
    // Once you have authentication set up you can append the userid to the front of the UUID to almost guarantee that there will be no duplication.
    const uniqueKey = `${userID}-${uuid}`;
    return uniqueKey;
}
function handleUploadProfilePhoto(req) {
    const userUUID = req.body["User-UUID"];
    const profilePhotoUniqueKey = generateUniqueKey(userUUID);
    console.log(`Photo key is: ${profilePhotoUniqueKey}`);
    // Check the database to see if their already exists a profile photo key. If so, use that key to delete the previous s3 object.
    // Put object in s3 bucket 
    accessS3.putObject(req.file.buffer, s3BucketName, profilePhotoUniqueKey);
    // Update database with the generated key
    accessUserDataDynamoDB.putPhotoKeyItem(userUUID, profilePhotoUniqueKey);
}
exports.handleUploadProfilePhoto = handleUploadProfilePhoto;
function handleDownloadProfilePhoto(req) {
    return __awaiter(this, void 0, void 0, function* () {
        const userUUIDs = req.query["User-UUIDs"];
        // Split the string by commas to get an array of user UUIDs
        const uuidArray = userUUIDs.split(",");
        let photoUrls = [];
        for (const uuid of uuidArray) {
            // Get the photo key from the UUIDs of the users with profile photo
            const photoKey = yield accessUserDataDynamoDB.getPhotoKey(uuid);
            // Access s3 to send back the photo
            photoUrls.push(yield accessS3.getObjectUrl(s3BucketName, `${photoKey}`));
        }
        return photoUrls;
    });
}
exports.handleDownloadProfilePhoto = handleDownloadProfilePhoto;
module.exports = { handleUploadProfilePhoto, handleDownloadProfilePhoto };
