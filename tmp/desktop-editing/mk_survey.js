// Creates a survey row for the real-backend Flutter test and prints {token, surveyId} as JSON.
const { owner, prisma } = require('./lib.js');
(async () => {
  const { user, token } = await owner('desk.phone@example.com');
  await prisma.survey.deleteMany({ where: { userId: user.id, title: 'PHONE E2E' } });
  const s = await prisma.survey.create({ data: { title: 'PHONE E2E', propertyAddress: '54 Gas Lane, Dartford, Kent', jobRef: 'VL1433', userId: user.id } });
  console.log(JSON.stringify({ token, surveyId: s.id }));
  await prisma.$disconnect();
})();
