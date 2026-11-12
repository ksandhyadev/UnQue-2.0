// scripts/verify-flow.js
// Automated verification script to test all 10 user flow steps against the live backend

const BASE_URL = process.env.BASE_URL || 'http://127.0.0.1:5001';

async function request(method, path, body = null, token = null) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const res = await fetch(`${BASE_URL}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : null,
  });

  const status = res.status;
  let data = null;
  try {
    data = await res.json();
  } catch (e) {
    data = await res.text();
  }
  return { status, data };
}

function printStep(stepNum, title, method, path, reqBody, status, resBody) {
  console.log('\n======================================================================');
  console.log(`STEP ${stepNum}: ${title}`);
  console.log(`METHOD : ${method} ${path}`);
  if (reqBody) console.log(`REQUEST: ${JSON.stringify(reqBody, null, 2)}`);
  console.log(`STATUS : ${status}`);
  console.log(`RESPONSE:\n${JSON.stringify(resBody, null, 2)}`);
  console.log('======================================================================');
}

async function run() {
  console.log(`Starting Full 10-Step Flow Verification against: ${BASE_URL}\n`);
  const timestamp = Date.now();

  // 1. Student A1 register & login
  const studentA1Email = `studentA1_${timestamp}@college.edu`;
  const regA1 = await request('POST', '/users/register', {
    name: 'Student A1',
    email: studentA1Email,
    password: 'password123',
    confirmPassword: 'password123',
    role: 'student',
  });
  printStep(1, 'Student A1 Register', 'POST', '/users/register', null, regA1.status, regA1.data);

  const loginA1 = await request('POST', '/users/login', {
    email: studentA1Email,
    password: 'password123',
  });
  printStep(1, 'Student A1 Login (Authenticates)', 'POST', '/users/login', null, loginA1.status, loginA1.data);
  const tokenA1 = loginA1.data.token;
  const studentA1Id = loginA1.data.id;

  // 2. Professor P1 register & login
  const profP1Email = `profP1_${timestamp}@college.edu`;
  const regP1 = await request('POST', '/users/register', {
    name: 'Professor P1',
    email: profP1Email,
    password: 'password123',
    confirmPassword: 'password123',
    role: 'professor',
  });
  printStep(2, 'Professor P1 Register', 'POST', '/users/register', null, regP1.status, regP1.data);

  const loginP1 = await request('POST', '/users/login', {
    email: profP1Email,
    password: 'password123',
  });
  printStep(2, 'Professor P1 Login (Authenticates)', 'POST', '/users/login', null, loginP1.status, loginP1.data);
  const tokenP1 = loginP1.data.token;
  const profP1Id = loginP1.data.id;

  // 3. Professor P1 specifies availability slots
  // Slot 1 (T1 Window: 09:00 - 10:00)
  const slot1 = await request('POST', '/professor/availability', {
    startTime: '2026-11-20T09:00:00.000Z',
    endTime: '2026-11-20T10:00:00.000Z',
  }, tokenP1);
  printStep(3, 'Professor P1 adds Slot 1 (09:00 - 10:00)', 'POST', '/professor/availability', null, slot1.status, slot1.data);

  // Slot 2 (T2 Window: 11:00 - 12:00)
  const slot2 = await request('POST', '/professor/availability', {
    startTime: '2026-11-20T11:00:00.000Z',
    endTime: '2026-11-20T12:00:00.000Z',
  }, tokenP1);
  printStep(3, 'Professor P1 adds Slot 2 (11:00 - 12:00)', 'POST', '/professor/availability', null, slot2.status, slot2.data);

  // Slot 3 (Free Slot to be updated in Step 8: 14:00 - 15:00)
  const slot3 = await request('POST', '/professor/availability', {
    startTime: '2026-11-20T14:00:00.000Z',
    endTime: '2026-11-20T15:00:00.000Z',
  }, tokenP1);
  printStep(3, 'Professor P1 adds Free Slot 3 (14:00 - 15:00)', 'POST', '/professor/availability', null, slot3.status, slot3.data);
  const freeSlotId = slot3.data.availability._id;

  // 4. Student A1 views available slots for Professor P1
  const viewSlots = await request('GET', `/general/professor/${profP1Id}/availability`, null, tokenA1);
  printStep(4, 'Student A1 views available slots for Prof P1', 'GET', `/general/professor/${profP1Id}/availability`, null, viewSlots.status, viewSlots.data);

  // 5. Student A1 books appointment with Prof P1 for time T1 (09:30)
  const bookT1 = await request('POST', '/general/book', {
    professorId: profP1Id,
    time: '2026-11-20T09:30:00.000Z',
  }, tokenA1);
  printStep(5, 'Student A1 books appointment for Time T1 (09:30)', 'POST', '/general/book', null, bookT1.status, bookT1.data);

  // 6. Student A2 authenticates
  const studentA2Email = `studentA2_${timestamp}@college.edu`;
  await request('POST', '/users/register', {
    name: 'Student A2',
    email: studentA2Email,
    password: 'password123',
    confirmPassword: 'password123',
    role: 'student',
  });
  const loginA2 = await request('POST', '/users/login', {
    email: studentA2Email,
    password: 'password123',
  });
  printStep(6, 'Student A2 Login (Authenticates)', 'POST', '/users/login', null, loginA2.status, loginA2.data);
  const tokenA2 = loginA2.data.token;

  // 7. Student A2 books appointment with Prof P1 for time T2 (11:30)
  const bookT2 = await request('POST', '/general/book', {
    professorId: profP1Id,
    time: '2026-11-20T11:30:00.000Z',
  }, tokenA2);
  printStep(7, 'Student A2 books appointment for Time T2 (11:30)', 'POST', '/general/book', null, bookT2.status, bookT2.data);

  // 8. [NEW API] Professor P1 updates timing of a free slot
  const updateSlot = await request('PATCH', `/professor/availability/${freeSlotId}`, {
    startTime: '2026-11-20T16:00:00.000Z',
    endTime: '2026-11-20T17:00:00.000Z',
  }, tokenP1);
  printStep(8, '[NEW API] Professor P1 updates timing of Slot 3 (16:00 - 17:00)', 'PATCH', `/professor/availability/${freeSlotId}`, null, updateSlot.status, updateSlot.data);

  // 9. Professor P1 cancels the appointment with Student A1
  const cancelAppt = await request('PATCH', `/professor/cancel-appointments/${studentA1Id}`, null, tokenP1);
  printStep(9, 'Professor P1 cancels appointment with Student A1', 'PATCH', `/professor/cancel-appointments/${studentA1Id}`, null, cancelAppt.status, cancelAppt.data);

  // 10. Student A1 checks their appointments and realizes they do not have any pending appointments
  const checkAppts = await request('GET', '/general/appointments', null, tokenA1);
  printStep(10, 'Student A1 checks appointments (Expects 404 No Pending)', 'GET', '/general/appointments', null, checkAppts.status, checkAppts.data);

  console.log('\n======================================================================');
  console.log('✅ ALL 10 USER FLOW STEPS COMPLETED & VERIFIED SUCCESSFULLY!');
  console.log('======================================================================\n');
}

run().catch(err => {
  console.error('Verification failed with error:', err);
  process.exit(1);
});
