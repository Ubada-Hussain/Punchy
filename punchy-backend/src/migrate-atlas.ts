import { MongoClient } from 'mongodb';

const LOCAL_URI = 'mongodb://127.0.0.1:27018/punchy?replicaSet=rs0';
const ATLAS_URI = 'mongodb+srv://ubadahussain52_db_user:ms12lfUQJKk3kFZP@cluster0.mij25up.mongodb.net/punchy?retryWrites=true&w=majority';

async function migrate() {
  console.log('Connecting to local MongoDB and Atlas MongoDB...');
  const localClient = new MongoClient(LOCAL_URI);
  const atlasClient = new MongoClient(ATLAS_URI);

  try {
    await localClient.connect();
    console.log('Connected to Local MongoDB');
    
    await atlasClient.connect();
    console.log('Connected to Atlas MongoDB Cluster!');

    const localDb = localClient.db('punchy');
    const atlasDb = atlasClient.db('punchy');

    const collections = await localDb.listCollections().toArray();
    console.log(`Found ${collections.length} collections locally.`);

    for (const col of collections) {
      const colName = col.name;
      if (colName.startsWith('system.')) continue;

      const docs = await localDb.collection(colName).find({}).toArray();
      console.log(`Collection [${colName}]: migrating ${docs.length} documents...`);

      if (docs.length > 0) {
        // Drop existing in atlas to avoid duplicate key errors
        try {
          await atlasDb.collection(colName).drop();
        } catch (e) {
          // ignore if collection doesn't exist
        }

        await atlasDb.collection(colName).insertMany(docs);
        console.log(`✓ Collection [${colName}] successfully migrated (${docs.length} docs).`);
      } else {
        console.log(`Collection [${colName}] is empty, skipping document copy.`);
      }
    }

    console.log('\n🎉 ALL DATA MIGRATED SUCCESSFULLY TO MONGODB ATLAS!');

  } catch (error) {
    console.error('Migration failed:', error);
  } finally {
    await localClient.close();
    await atlasClient.close();
  }
}

migrate();
