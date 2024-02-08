import { S3Client, GetObjectCommand, PutObjectCommand, DeleteObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

export class AccessS3 {
    
	constructor(bucketRegion) {
		this.client = new S3Client({ region: bucketRegion });
	}

	async getObjectUrl(bucket, key) {
		const input = {
			"Bucket": bucket,
			"Key": key
		};
    
		const command = new GetObjectCommand(input);

		await this.client.send(command);
		const url = await getSignedUrl(this.client, command, { expiresIn: 60});

		return url;
	}
    
    
	async putObject(body, bucket, key) {
		const input = {
			"Body": body,
			"Bucket": bucket,
			"Key": key
		};
		const command = new PutObjectCommand(input);
		await this.client.send(command);
	}
    
	// Add delete
}

module.exports = { AccessS3 };