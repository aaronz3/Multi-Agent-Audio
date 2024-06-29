This was a personal project in which I used WebRTC's API and Amazons' EC2 servers in order to allow users to communicate with one another by audio or text. Users connect to the EC2 server by websockets in order to relay their IP address and SDP (see RFC 8866) to other users. When other users respond with their own IP address, I then relay this back to the sender. After this exchange, users can send data directly to each other without sending their data to the server. 

Some capabilities that I include are as follows.

-	A database (i.e. Amazon’s Dynamo DB) to store information that users would like to share to others even after closing or deleting the app.
-	Allowing users to reconnect to one another after changing their IP addresses. Hence, if a user switches from their home router to cellular data, they can still reconnect.
-	Assigning users into rooms after pressing the connect button.
-	An audio bar for users to see how loud others are talking.

[Here](https://youtu.be/Qe65peTSklQ) and [here](https://youtu.be/UyuEPVv3PWc) are two demonstration videos.
