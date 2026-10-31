const mongoose = require('mongoose');
const dotenv = require('dotenv');
dotenv.config();

const day1Questions = [
  'Hello! Welcome to Voxora. What is your name and where are you from?',
  'Nice to meet you! What do you do for work or study?',
  'What are your favorite hobbies or what do you like to do on weekends?',
  'Why do you want to learn English, and what is your dream speaking goal?',
  'Can you say one full sentence: "I am practicing English every day to speak fluently and confidently"?'
];

async function updateDb() {
  const uri = process.env.MONGO_URI || 'mongodb://localhost:27017/voxora';
  console.log('Connecting to:', uri);
  await mongoose.connect(uri);

  // 1. Update LearningPlans Day 1
  const lpRes = await mongoose.connection.collection('learningplans').updateMany(
    { 'lessons.day': 1 },
    { $set: { 'lessons.$[elem].miraQuestions': day1Questions } },
    { arrayFilters: [{ 'elem.day': 1 }] }
  );
  console.log('Updated learningplans modifiedCount:', lpRes.modifiedCount);

  // 2. Update CurriculumTemplates Day 1
  const ctRes = await mongoose.connection.collection('curriculumtemplates').updateMany(
    { day: 1 },
    { $set: { miraQuestions: day1Questions } }
  );
  console.log('Updated curriculumtemplates modifiedCount:', ctRes.modifiedCount);

  // Verify
  const plan = await mongoose.connection.collection('learningplans').findOne({});
  const day1 = plan?.lessons?.find(l => l.day === 1);
  console.log('Verified Plan Day 1 questions count:', day1?.miraQuestions?.length);
  console.log('Verified Plan Day 1 questions:', day1?.miraQuestions);

  await mongoose.disconnect();
  console.log('Done!');
}

updateDb().catch(err => {
  console.error('Error updating DB:', err);
  process.exit(1);
});
