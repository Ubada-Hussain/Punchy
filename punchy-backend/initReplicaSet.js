const { MongoClient } = require('mongodb');

async function main() {
  // Connect to the mongod instance running on localhost:27017
  const uri = "mongodb://127.0.0.1:27018/?directConnection=true";
  const client = new MongoClient(uri);

  try {
    await client.connect();
    console.log("Connected to MongoDB.");

    // Run the replSetInitiate command against the admin database
    const db = client.db('admin');
    const result = await db.command({ replSetInitiate: {
      _id: "rs0",
      members: [
        { _id: 0, host: "127.0.0.1:27018" }
      ]
    } });

    console.log("Replica Set initiated successfully!");
    console.log(result);
  } catch (error) {
    if (error.codeName === 'AlreadyInitialized') {
      console.log("Replica Set is already initiated.");
    } else {
      console.error("Error initiating Replica Set:", error);
    }
  } finally {
    await client.close();
  }
}

main().catch(console.error);
