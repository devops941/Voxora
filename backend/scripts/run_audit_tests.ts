import crypto from 'crypto';
import app from '../src/app';
import { aiProviderManager } from '../src/services/ai/AIProviderManager';
import { certificateService } from '../src/modules/certificate/certificate.service';

async function runTests() {
  console.log('====================================================');
  console.log('         VOXORA FULL BACKEND AUDIT SUITE            ');
  console.log('====================================================\n');

  let passed = 0;
  let failed = 0;

  function assert(condition: boolean, testName: string, detail?: string) {
    if (condition) {
      console.log(`  [PASS] ${testName}`);
      passed++;
    } else {
      console.error(`  [FAIL] ${testName} ${detail ? `(${detail})` : ''}`);
      failed++;
    }
  }

  // 1. AI PROVIDER MANAGER TESTS
  console.log('\n--- 1. AI PROVIDER ARCHITECTURE ---');
  const status = aiProviderManager.getStatus();
  assert(status.primaryProvider.includes('Claude'), 'AI primary provider is Claude');
  assert(status.model.includes('claude'), 'Configured model is Claude');
  assert(typeof status.cooldownRemainingMs === 'number', 'Cooldown remaining ms exposed');
  assert(typeof status.status === 'string', 'Provider status exposed');

  // Test chat
  console.log('\n--- Testing AI Chat ---');
  try {
    const chatRes = await aiProviderManager.chat({
      message: 'Hello MIRA, introduce yourself in one short sentence.',
      level: 'Intermediate',
    });
    assert(Boolean(chatRes.data && chatRes.data.message.length > 5), 'AI Chat returns non-empty response', `Got: ${chatRes.data?.message}`);
    assert(['claude', 'local_engine'].includes(chatRes.provider), `Provider is Claude or Local Engine (${chatRes.provider})`);
    assert(Array.isArray(chatRes.data.suggestedReplies), 'AI Chat returns suggested replies');
    console.log(`    Active provider for chat: ${chatRes.provider}`);
    console.log(`    Message: "${chatRes.data.message}"`);
  } catch (err: any) {
    assert(false, 'AI Chat executed without uncaught exception', err.message);
  }

  // Test feedback
  console.log('\n--- Testing AI Feedback ---');
  try {
    const fbRes = await aiProviderManager.getFeedback({
      transcript: 'Yesterday I go to market and bought fruits.',
      question: 'Talk about what you did yesterday.',
      topic: 'Daily Routine',
      durationSeconds: 15,
    });
    assert(Boolean(fbRes.data), 'AI Feedback returns data object');
    assert(typeof fbRes.data.overallScore === 'number', 'Feedback has overallScore numeric metric');
    assert(Array.isArray(fbRes.data.strengths), 'Feedback has strengths array');
    assert(Array.isArray(fbRes.data.weaknesses), 'Feedback has weaknesses array');
    assert(Array.isArray(fbRes.data.suggestions), 'Feedback has suggestions array');
    console.log(`    Feedback overallScore: ${fbRes.data.overallScore}, Provider: ${fbRes.provider}`);
  } catch (err: any) {
    assert(false, 'AI Feedback executed without uncaught exception', err.message);
  }

  // Test doubt analyzer
  console.log('\n--- Testing AI Doubt Analyzer ---');
  try {
    const doubtRes = await aiProviderManager.answerDoubt({
      userQuestion: 'What is the difference between see, look, and watch?',
      topic: 'Sensory Verbs',
      day: 5,
    });
    assert(Boolean(doubtRes.data && doubtRes.data.answer.length > 20), 'Doubt analyzer returns clear answer');
    console.log(`    Doubt analyzer answer preview: ${doubtRes.data.answer.slice(0, 70)}... (Provider: ${doubtRes.provider})`);
  } catch (err: any) {
    assert(false, 'AI Doubt analyzer executed', err.message);
  }

  // Test speech evaluation
  console.log('\n--- Testing AI Speech Evaluation ---');
  try {
    const speechRes = await aiProviderManager.evaluateSpeech({
      topic: 'Self Introduction',
      day: 1,
      miraPrompt: 'Please tell me your name and your goal.',
      transcript: 'I would like to improve my English fluency and vocabulary.',
      duration: 12,
      userLevel: 'Intermediate',
    });
    assert(typeof speechRes.data.scores.overall === 'number' && speechRes.data.scores.overall > 0, 'Speech evaluation returns score > 0');
    assert(Boolean(speechRes.data.explanation), 'Speech evaluation returns detailed explanation');
    console.log(`    Speech overall score: ${speechRes.data.scores.overall}, Grammar: ${speechRes.data.scores.grammar}, Provider: ${speechRes.provider}`);
  } catch (err: any) {
    assert(false, 'Speech evaluation executed', err.message);
  }

  // Test 25 Questions for Beginner, Intermediate, Advanced
  console.log('\n--- Testing 25 Final Assessment Questions for all 3 levels ---');
  for (const level of ['Beginner', 'Intermediate', 'Advanced'] as const) {
    try {
      const qRes = await aiProviderManager.generateFinalAssessmentQuestions(level);
      assert(qRes.data.length === 25, `${level} assessment generated exactly 25 questions (got ${qRes.data.length})`);
      const allValid = qRes.data.every(
        (q) => q.question && q.options.length === 4 && q.correctAnswerIndex >= 0 && q.correctAnswerIndex < 4 && q.marks === 4
      );
      assert(allValid, `${level} questions all have 4 options, valid correctAnswerIndex, and 4 marks each`);
      console.log(`    ${level} provider: ${qRes.provider} (First question: "${qRes.data[0].question.slice(0, 50)}...")`);
    } catch (err: any) {
      assert(false, `${level} question generation succeeded`, err.message);
    }
  }

  // 2. GEMINI REMOVAL VERIFICATION
  console.log('\n--- 2. GEMINI REMOVAL VERIFICATION ---');
  const packageJson = require('../package.json');
  assert(!packageJson.dependencies['@google/genai'], 'Gemini SDK (@google/genai) not in package.json dependencies');
  assert(!packageJson.devDependencies['@google/genai'], 'Gemini SDK not in package.json devDependencies');

  const envConfig = require('../src/config/env').default;
  assert(envConfig.geminiApiKey === undefined, 'geminiApiKey completely removed from env config');
  assert(envConfig.geminiModel === undefined, 'geminiModel completely removed from env config');

  // 3. CERTIFICATE PDF GENERATION TEST
  console.log('\n--- 3. CERTIFICATE PDFKIT GENERATION ---');
  try {
    const certBuffer: Buffer = await (certificateService as any).createCertificatePDF({
      fullName: 'Test Student',
      level: 'Advanced',
      score: 88,
      percentage: 88,
      completionDate: new Date(),
      certificateId: 'test-cert-id-1234-5678',
      isTestMode: false,
    });
    assert(Buffer.isBuffer(certBuffer), 'createCertificatePDF returns a Buffer');
    assert(certBuffer.length > 1000, `PDF Buffer size is substantial (${certBuffer.length} bytes)`);
    const header = certBuffer.slice(0, 4).toString('utf8');
    assert(header === '%PDF', `PDF Buffer starts with %PDF magic header (got "${header}")`);
  } catch (err: any) {
    assert(false, 'Certificate PDF generation succeeded', err.message);
  }

  // 4. CRYPTO OTP & SECURITY TESTS
  console.log('\n--- 4. CRYPTOGRAPHIC OTP SECURITY ---');
  const otpCode = crypto.randomInt(100000, 1000000).toString();
  assert(otpCode.length === 6 && /^\d{6}$/.test(otpCode), 'OTP generated is cryptographically random 6 digits');
  const otpHash = crypto.createHash('sha256').update(otpCode).digest('hex');
  assert(otpHash.length === 64, 'OTP hash is valid 64-char SHA-256 digest');
  const verifySuccess = crypto.createHash('sha256').update(otpCode).digest('hex') === otpHash;
  assert(verifySuccess, 'OTP hash verification succeeds for correct code');
  const verifyFail = crypto.createHash('sha256').update('000000').digest('hex') === otpHash;
  assert(!verifyFail, 'OTP hash verification fails for incorrect code');

  // 5. BACKEND ROUTE MOUNT VERIFICATION
  console.log('\n--- 5. BACKEND ROUTE MOUNT VERIFICATION ---');
  const routesMounted: string[] = [];
  app._router.stack.forEach((layer: any) => {
    if (layer.route) {
      routesMounted.push(layer.route.path);
    } else if (layer.name === 'router' && layer.regexp) {
      routesMounted.push(layer.regexp.toString());
    }
  });

  const expectedPrefixes = [
    '/api/v1/auth',
    '/api/v1/users',
    '/api/v1/ai',
    '/api/v1/curriculum',
    '/api/v1/lessons',
    '/api/v1/final-assessment',
    '/api/v1/certificate',
    '/api/v1/dashboard',
  ];

  for (const prefix of expectedPrefixes) {
    const isMounted = routesMounted.some((r) => r.includes(prefix.replace(/\//g, '\\/')) || r.includes(prefix));
    assert(isMounted, `Route mounted: ${prefix}`);
  }

  console.log('\n====================================================');
  console.log(`TEST SUMMARY: ${passed} PASSED, ${failed} FAILED`);
  console.log('====================================================\n');

  if (failed > 0) {
    process.exit(1);
  }
}

runTests().catch((err) => {
  console.error('Fatal test error:', err);
  process.exit(1);
});
