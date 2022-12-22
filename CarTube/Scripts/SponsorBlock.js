// Modified from https://greasyfork.org/en/scripts/453320-simple-sponsor-skipper

(async function () {
     "use strict";
     async function go(videoId) {
         console.log("New video ID: " + videoId);

         const inst = s3settings.instance || "sponsor.ajay.app";
         let segurl = "";
         let result = [];
         let rBefore = -1;
         let rPoi = null;
         let cat = [];
         if (s3settings.categories & categories.intro)
             cat.push("intro");
         if (s3settings.categories & categories.outro)
             cat.push("outro");
         if (s3settings.categories & categories.interaction)
             cat.push("interaction");
         if (s3settings.categories & categories.selfpromo)
             cat.push("selfpromo");
         if (s3settings.categories & categories.preview)
             cat.push("preview");
         if (s3settings.categories & categories.music_offtopic)
             cat.push("music_offtopic");
         if (s3settings.categories & categories.filler)
             cat.push("filler");
         if ((s3settings.categories & categories.sponsor) || cat.length === 0)
             cat.push("sponsor");
         if (s3settings.notifications)
             cat.push("poi_highlight");

         if (s3settings.disable_hashing) {
             segurl = 'https://' + inst + '/api/skipSegments?videoID=' + videoId + "&categories=" + encodeURIComponent(JSON.stringify(shuffle(cat)));
         }
         else {
             let vidsha256 = await sha256(videoId);
             console.log("SHA256 hash: " + vidsha256);
             segurl = 'https://' + inst + '/api/skipSegments/' + vidsha256.substring(0, 4) + "?categories=" + encodeURIComponent(JSON.stringify(shuffle(cat)));
         }
         console.log(segurl + " me here");

         const resp = await (async function () {
             const response = await fetch(segurl, {
                 method: 'GET',
                 headers: {
                     'Accept': 'application/json'
                 }
             });
             const json = await response.json()
             return json;
         })();
         try {
             let response;
             if (s3settings.disable_hashing)
                 response = JSON.parse("[{\"videoID\":\"" + videoId + "\",\"segments\":" + JSON.stringify(resp) + "}]");
             else
                 response = JSON.parse(JSON.stringify(resp));

             for (let x = 0; x < response.length; x++) {
                 if (response[x].videoID === videoId) {
                     rBefore = response[x].segments.length;
                     result = processSegments(response[x].segments);
                     if (result[result.length - 1].category === "poi_highlight") {
                         rPoi = result[result.length - 1].segment[0];
                         result.splice((result.length - 1), 1);
                     }
                     break;
                 }
             }
         } catch (e) { result = []; }
         let x = 0;
         let prevTime = -1;
         let favicon = document.querySelector('link[rel=icon]');
         if (favicon && favicon.hasAttribute('href')) {
             favicon = favicon.href;
         } else {
             favicon = null;
         }
         if (result.length > 0) {
             let player = await (function () {
                 return new Promise(resolve => {
                     let pltimer = window.setInterval(function () {
                         let plr = document.querySelector('[id="movie_player"] video') || document.getElementById("player_html5_api") || document.getElementById("player") || document.getElementById("video") || document.getElementById("vjs_video_3_html5_api");
                         if (!!plr && !!plr.video && plr.video.readyState >= 3) {
                             window.clearInterval(pltimer);
                             resolve(plr.video);
                         }
                         else if (!!plr && plr.readyState >= 3) {
                             window.clearInterval(pltimer);
                             resolve(plr);
                         }
                     }, 10);
                 });
             })();
             const pfunc = function () {
                 if (s3settings.notifications && !!rPoi && player.currentTime < rPoi) {
                     const date = new Date(0);
                     date.setSeconds(Math.floor(rPoi));
                 }
             };
             const vfunc = function () {
                 if (location.hostname !== 'odysee.com' &&
                     location.pathname.indexOf(videoId) === -1 && location.search.indexOf('v=' + videoId) === -1) {
                     player.removeEventListener('timeupdate', vfunc);
                     player.removeEventListener('play', pfunc);
                     return;
                 }

                 if (!player.paused && x < result.length && player.currentTime >= result[x].segment[0]) {
                     if (player.currentTime < result[x].segment[1]) {
                         player.currentTime = result[x].segment[1];
                         console.log("Skipping " + result[x].category + " segment (" + (x + 1) + " out of " + result.length + ") from " + result[x].segment[0] + " to " + result[x].segment[1]);
                     }
                     x++;
                 } else if (player.currentTime < prevTime) {
                     for (let s = 0; s < result.length; s++) {
                         if (player.currentTime < result[s].segment[1]) {
                             x = s;
                             console.log("Next segment is " + s);
                             break;
                         }
                     }
                 }
                 prevTime = player.currentTime;
             };
             player.addEventListener('timeupdate', vfunc);
             player.addEventListener('play', pfunc);
         }
     }

     function processSegments(segments) {
         if (typeof segments === 'object') {
             let newSegments = [];
             let highlight = null;
             let hUpvotes = s3settings.upvotes - 1;
             for (let x = 0; x < segments.length; x++) {
                 if (segments[x].category === "poi_highlight" && segments[x].votes > hUpvotes) {
                     highlight = segments[x];
                     hUpvotes = segments[x].upvotes;
                 } else if (x > 0 && newSegments[newSegments.length - 1].segment[1] >= segments[x].segment[0] && newSegments[newSegments.length - 1].segment[1] < segments[x].segment[1] && segments[x].votes >= s3settings.upvotes) {
                     newSegments[newSegments.length - 1].segment[1] = segments[x].segment[1];
                     newSegments[newSegments.length - 1].category = "combined";
                     console.log(x + " combined with " + (newSegments.length - 1));
                 } else if (segments[x].votes < s3settings.upvotes || (x > 0 && newSegments[newSegments.length - 1].segment[1] >= segments[x].segment[0] && newSegments[newSegments.length - 1].segment[1] >= segments[x].segment[1])) {
                     console.log("Ignoring segment " + x);
                 } else {
                     newSegments.push(segments[x]);
                     console.log((newSegments.length - 1) + " added");
                 }
             }
             if (!!highlight)
                 newSegments.push(highlight);
             return newSegments;
         } else {
             return [];
         }
     }

     async function sha256(message) {
         // encode as UTF-8
         const msgBuffer = new TextEncoder().encode(message);

         // hash the message
         const hashBuffer = await crypto.subtle.digest('SHA-256', msgBuffer);

         // convert ArrayBuffer to Array
         const hashArray = Array.from(new Uint8Array(hashBuffer));

         // convert bytes to hex string
         const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
         return hashHex;
     }

     function shuffle(array) {
         let currentIndex = array.length, randomIndex;

         // While there remain elements to shuffle.
         while (currentIndex != 0) {

             // Pick a remaining element.
             randomIndex = Math.floor(Math.random() * currentIndex);
             currentIndex--;

             // And swap it with the current element.
             [array[currentIndex], array[randomIndex]] = [
                 array[randomIndex], array[currentIndex]];
         }

         return array;
     }

     const categories = {
         sponsor: 1,
         intro: 2,
         outro: 4,
         interaction: 8,
         selfpromo: 16,
         preview: 32,
         music_offtopic: 64,
         filler: 128
     }

     let s3settings;

     s3settings = JSON.parse('{ "categories":1, "upvotes":-2, "notifications":true, "disable_hashing":false, "instance":"sponsor.ajay.app", "darkmode":-1 }');
     if (navigator.userAgent.toLowerCase().indexOf('pale moon') !== -1
         || navigator.userAgent.toLowerCase().indexOf('mypal') !== -1
         || navigator.userAgent.toLowerCase().indexOf('male poon') !== -1) {
         s3settings.disable_hashing = true;
     }
     let oldVidId = "";
     let params = new URLSearchParams(location.search);
     if (params.has('v')) {
         oldVidId = params.get('v');
         go(oldVidId);
     } else if (location.pathname.indexOf('/embed/') === 0 || location.pathname.indexOf('/v/') === 0) {
         oldVidId = location.pathname.replace('/v/', '').replace('/embed/', '').split('/')[0];
         go(oldVidId);
     }

     window.addEventListener("load", function () {
         let observer = new MutationObserver(function (mutations) {
             params = new URLSearchParams(location.search);
             if (params.has('v') && params.get('v') !== oldVidId) {
                 oldVidId = params.get('v');
                 go(oldVidId);
             } else if ((location.pathname.indexOf('/embed/') === 0 || location.pathname.indexOf('/v/') === 0) && location.pathname.indexOf(oldVidId) === -1) {
                 oldVidId = location.pathname.replace('/v/', '').replace('/embed/', '').split('/')[0];
                 go(oldVidId);
             } else if (!params.has('v') && location.pathname.indexOf('/embed/') === -1 && location.pathname.indexOf('/v/') === -1) {
                 oldVidId = "";
             }
         });

         let config = {
             childList: true,
             subtree: true
         };

         observer.observe(document.body, config);
     });
 })();
