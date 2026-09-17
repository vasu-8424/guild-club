'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "92b10f88dee95d96af102162009ebd66",
"assets/AssetManifest.bin.json": "a7a65a415c59fab61176c20692ad61c6",
"assets/AssetManifest.json": "2beae7e196ae7d13cabeac5c46fa2c5c",
"assets/assets/fonts/CormorantGaramond-600Italic.ttf": "774903cb2d0fccb209358b923a7ad202",
"assets/assets/fonts/CormorantGaramond-Italic-VariableFont_wght.ttf": "fd5aaca0d720740005cbd86b1462fdd2",
"assets/assets/fonts/CormorantGaramond-weight_1.ttf": "cea5d91e322c6886560026bcced5ec5f",
"assets/assets/fonts/CormorantGaramond-weight_2.ttf": "1e040c7442e6aaf3bbd7f9ed681856fa",
"assets/assets/fonts/CormorantGaramond-weight_3.ttf": "4b337fc51b255117d4c2be97ef10ec4e",
"assets/assets/fonts/CormorantGaramond-weight_4.ttf": "9cd9c993fc9f26e8687c78f0dc0ff875",
"assets/assets/fonts/Outfit-400.ttf": "5b9f52d21b290a4c1b2d3cc3dcdb5b9b",
"assets/assets/fonts/Outfit-500.ttf": "85118b24c3cac31f1e9bfc45251f4555",
"assets/assets/fonts/Outfit-600.ttf": "98ccc2b7f18991a5126a91ac56fbb1fc",
"assets/assets/fonts/Outfit-700.ttf": "98ccc2b7f18991a5126a91ac56fbb1fc",
"assets/assets/fonts/Outfit-900.ttf": "98ccc2b7f18991a5126a91ac56fbb1fc",
"assets/assets/fonts/Outfit-VariableFont_wght.ttf": "e31a3aa5fce3366bcadb8e9027f26178",
"assets/assets/fonts/PlusJakartaSans-400.ttf": "3c34e8199b247555cc2b9c28f2680700",
"assets/assets/fonts/PlusJakartaSans-500.ttf": "91532282274f638eaa33d973153054ac",
"assets/assets/fonts/PlusJakartaSans-600.ttf": "75bdc0180d8745ed7fa9b6a64a07b7df",
"assets/assets/fonts/PlusJakartaSans-700.ttf": "3a6205ffa0b4d4895a2db59e7aca8c8d",
"assets/assets/fonts/PlusJakartaSans-VariableFont_wght.ttf": "6b68a2205325ea49b65af07e4061f320",
"assets/assets/images/auth_hero_character.png": "ecccacb9fd63e1a9d14ccdfe099347a3",
"assets/assets/images/categories/behavioural_therapy.png": "e8fe15580ae009c73d4928bdd71220f1",
"assets/assets/images/categories/child_development.png": "bee3ad157433ed514f9b41d8afa61134",
"assets/assets/images/categories/interior_designing.png": "660ea8a5dad5e2b7a4c970c8524e4d23",
"assets/assets/images/categories/occupational_therapy.png": "ccb687222feb6235552127cead9a9edb",
"assets/assets/images/categories/play_schools.png": "5b0c7cc71b70680ce5a8e5210753c528",
"assets/assets/images/categories/schools.png": "af748cef6cc85d173b5b91bdc9fac8dc",
"assets/assets/images/categories/special_education.png": "2ddf65d9adde5b0a47d59d5b15a17262",
"assets/assets/images/categories/speech_therapy.png": "f4d5931ef6a878bc8c4e86bfa6e0de20",
"assets/assets/images/login_hero.png": "792e62029a07a24598a5e5da9ea422fd",
"assets/FontManifest.json": "56b34ddfac720d772061c75171b6a5b8",
"assets/fonts/MaterialIcons-Regular.otf": "8fd99a20d8c61f4a712bd8519289a580",
"assets/NOTICES": "210018483d79a4330a9c67d7d7cf79e8",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Brands-Regular-400.otf": "706b13a761d261d759c0a8d557ccfdcb",
"assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Free-Regular-400.otf": "46be639d952abe98effde36da35e7701",
"assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Free-Solid-900.otf": "48b92e8451309fdcb73d294f0f6e9830",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"flutter_bootstrap.js": "a4b1ba86d3a5241cee5ebdd5d71d5920",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "751a4b75d519b2753567652496e8c2c2",
"/": "751a4b75d519b2753567652496e8c2c2",
"main.dart.js": "af0a5b97084eaff37a7e6d6688cc7101",
"manifest.json": "c18723a4f146b2bc5d669a929538e219",
"vercel.json": "fc035ddacc795e602751aab604299f2e",
"version.json": "d28fe8c99e158b29533069dfcda0cc15"};
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
