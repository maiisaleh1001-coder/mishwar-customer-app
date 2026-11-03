// البروتوتايب كتطبيق متسطب (index.html و provider.html بيسجّلوه بس لما يتفتحوا كتطبيق)
// بيجيب من النت الأول علشان أي push يبان على طول، وبيحتفظ بآخر نسخة علشان التطبيق يفتح من غير نت.
const CACHE = 'mishwar-app-v1';

// اللي بيتحفظ من أول فتحة. أي ملف تاني بيتحفظ أول ما يتطلب.
// لو ضفت صورة جديدة في ui/assets، ضيفها هنا علشان تبان من غير نت من أول مرة.
const CORE = [
  'index.html', 'provider.html', 'customer.webmanifest', 'provider.webmanifest',
  'assets/saudi-riyal-symbol.svg',
  'assets/icons/customer-192.png', 'assets/icons/customer-512.png', 'assets/icons/customer-apple-touch-180.png', 'assets/icons/customer-maskable-512.png',
  'assets/icons/provider-192.png', 'assets/icons/provider-512.png', 'assets/icons/provider-apple-touch-180.png', 'assets/icons/provider-maskable-512.png',
  'assets/map/riyadh-malqa.svg', 'assets/map/riyadh-narjis.svg', 'assets/map/riyadh-olaya.svg',
  'assets/onboarding/ob-calendar.png', 'assets/onboarding/ob-car.png', 'assets/onboarding/ob-chat.png', 'assets/onboarding/ob-companion.png',
  'assets/onboarding/ob-gov.png', 'assets/onboarding/ob-parcel.png', 'assets/onboarding/ob-pin.png', 'assets/onboarding/ob-shield.png',
  'assets/onboarding/ob-star.png', 'assets/onboarding/ob-wallet.png',
  'assets/photos/chat-gate.jpg', 'assets/photos/parcel-dropoff.jpg', 'assets/photos/parcel-pickup.jpg',
];
// الخطوط من Google بتتحفظ برضه، علشان الشكل يفضل زي ما هو من غير نت
const FONTS = /^https:\/\/fonts\.(googleapis|gstatic)\.com\//;

self.addEventListener('install', e => {
  self.skipWaiting();
  // ملف واحد ناقص ما يوقفش الباقي
  e.waitUntil(caches.open(CACHE).then(c => Promise.all(CORE.map(u => c.add(new Request(u, { cache: 'reload' })).catch(() => {})))));
});

self.addEventListener('activate', e => {
  e.waitUntil(caches.keys()
    .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});

// التطبيق المتسطب بيتفتح بـ ?app=1. اللينك العادي وصفحة العرض بيعدّوا على النت زي ما هما، من غير كاش
const APP = /[?&]app=1\b/;
async function fromApp(e) {
  if (e.request.mode === 'navigate') return APP.test(new URL(e.request.url).search);
  const c = e.clientId && await self.clients.get(e.clientId);
  return !!c && APP.test(new URL(c.url).search);
}

function netFirst(req) {
  const url = new URL(req.url), same = url.origin === location.origin;
  // no-cache: يسأل GitHub كل مرة بدل ما ياخد نسخة المتصفح القديمة
  const net = same ? fetch(req.url, { cache: 'no-cache', credentials: 'same-origin' }) : fetch(req);
  return net.then(res => {
    if (res.ok || res.type === 'opaque') { const copy = res.clone(); caches.open(CACHE).then(c => c.put(req, copy)); }
    return res;
  }).catch(() => caches.match(req).then(hit => hit || caches.match(req, { ignoreSearch: true }))
    .then(hit => hit || (req.mode === 'navigate' ? caches.match(url.pathname.endsWith('provider.html') ? 'provider.html' : 'index.html') : Response.error())));
}

self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;
  if (new URL(req.url).origin !== location.origin && !FONTS.test(req.url)) return;
  e.respondWith(fromApp(e).then(app => app ? netFirst(req) : fetch(req)));
});
