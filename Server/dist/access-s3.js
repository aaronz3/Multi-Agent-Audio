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
exports.AccessS3 = void 0;
const client_s3_1 = require("@aws-sdk/client-s3");
const s3_request_presigner_1 = require("@aws-sdk/s3-request-presigner");
class AccessS3 {
    constructor(bucketRegion) {
        this.client = new client_s3_1.S3Client({ region: bucketRegion });
    }
    getObjectUrl(bucket, key) {
        return __awaiter(this, void 0, void 0, function* () {
            const input = {
                "Bucket": bucket,
                "Key": key
            };
            const command = new client_s3_1.GetObjectCommand(input);
            yield this.client.send(command);
            const url = yield (0, s3_request_presigner_1.getSignedUrl)(this.client, command, { expiresIn: 60 });
            return url;
        });
    }
    putObject(body, bucket, key) {
        return __awaiter(this, void 0, void 0, function* () {
            const input = {
                "Body": body,
                "Bucket": bucket,
                "Key": key
            };
            const command = new client_s3_1.PutObjectCommand(input);
            yield this.client.send(command);
        });
    }
}
exports.AccessS3 = AccessS3;
module.exports = { AccessS3 };
