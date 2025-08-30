'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"manifest.json": "4f0609fc959ed573c4669327a7397980",
"icons/apple-touch-icon.png": "d0d654734d45514cbca3167e968dc6e0",
"icons/splash.png": "25afaaa8deea99320b14f21bb2d23a19",
"icons/favicon-96x96.png": "f198c4dd923c9b993bfcd3e89fd78f80",
"icons/web-app-manifest-192x192.png": "fad7a0229427954481d4a5a90521067e",
"icons/favicon.svg": "eb32873f58c4fe29385e6c19defba1ee",
"icons/favicon.ico": "7ac731b7c69c046320c5dd8dbd97807e",
"icons/web-app-manifest-512x512.png": "9feb4bbe50468fbce313888a237e3190",
"main.dart.js": "a871863445e949200b593dcdd3054434",
"version.json": "231ca94647cc5f4ec292f9bf7c4ea189",
"assets/NOTICES": "47bedc5a701b84783898e5be430c40c1",
"assets/dotenv": "44ff4fbd838eb2a9837ba5fef2284492",
"assets/fonts/MaterialIcons-Regular.otf": "0f0441408e4c3dbbf4d7b89d74b0421b",
"assets/AssetManifest.json": "50267ae0955f1bc6d415dd43250c623d",
"assets/assets/avatars/rabbit.png": "2a7eff53b3a162c24e86faa1720b0063",
"assets/assets/avatars/bear.png": "0d940ebda7bec8e846492d53dbddde68",
"assets/assets/avatars/tiger.png": "95ee08b6de0eb2fac67d902cd526b04c",
"assets/assets/avatars/pig.png": "b26d4d0617815e8916f414841d40d83d",
"assets/assets/avatars/cow.png": "760e40a58457e9d275170bf35eda8cdd",
"assets/assets/avatars/lion.png": "130c1b518d88199fbca5e51734935212",
"assets/assets/avatars/fox.png": "34802a3381de3cd86ef3c4c7e4e36443",
"assets/assets/avatars/panda.png": "7939e2dec24f3b67521c37bb2e642163",
"assets/assets/avatars/dog.png": "bb5ec199d14cb7fe1b5ebbef928f6420",
"assets/assets/music/wait.mp3": "15f55f2abb082cadd1036b553d75911d",
"assets/assets/google_fonts/BricolageGrotesque-ExtraBold.ttf": "5bfb4fa1f8907c768231d97bc27e8df9",
"assets/assets/google_fonts/BricolageGrotesque-Regular.ttf": "6586800789b30b19bbaeb349ca5d240a",
"assets/assets/google_fonts/BricolageGrotesque-Medium.ttf": "1363130c7bdf956d164cb7e605619849",
"assets/assets/google_fonts/BricolageGrotesque-Light.ttf": "a1f1439e622b6998c9b639bbf0a23f01",
"assets/assets/google_fonts/BricolageGrotesque-Bold.ttf": "2f7de7a336f650f9cee5ed919cc3b003",
"assets/assets/google_fonts/BricolageGrotesque-SemiBold.ttf": "e5b5fc505484ff3ca24da73cba67c660",
"assets/assets/google_fonts/BricolageGrotesque-ExtraLight.ttf": "0e66297d36d7f24484f3ec8a2232d6fc",
"assets/assets/google_fonts/OFL.txt": "c01c6f2840f06aacc97899ab09ec0e01",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "3d079882e0e647805a2f9a5664821595",
"assets/AssetManifest.bin": "c19828b2fd6a6bddb67d4cd53a9f0c53",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"flutter_bootstrap.js": "2ff78f188d0b6cfdf46426b2fc2bf07c",
"index.html": "ba85afe763653250dae3a51b4362d44f",
"/": "ba85afe763653250dae3a51b4362d44f"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
