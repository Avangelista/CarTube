!function(){"use strict";function o(){var o=window,t=document;if(!("scrollBehavior"in t.documentElement.style&&!0!==o.__forceSmoothScrollPolyfill__)){var l,e=o.HTMLElement||o.Element,r=468,i={scroll:o.scroll||o.scrollTo,scrollBy:o.scrollBy,elementScroll:e.prototype.scroll||n,scrollIntoView:e.prototype.scrollIntoView},s=o.performance&&o.performance.now?o.performance.now.bind(o.performance):Date.now,c=(l=o.navigator.userAgent,new RegExp(["MSIE ","Trident/","Edge/"].join("|")).test(l)?1:0);o.scroll=o.scrollTo=function(){void 0!==arguments[0]&&(!0!==f(arguments[0])?h.call(o,t.body,void 0!==arguments[0].left?~~arguments[0].left:o.scrollX||o.pageXOffset,void 0!==arguments[0].top?~~arguments[0].top:o.scrollY||o.pageYOffset):i.scroll.call(o,void 0!==arguments[0].left?arguments[0].left:"object"!=typeof arguments[0]?arguments[0]:o.scrollX||o.pageXOffset,void 0!==arguments[0].top?arguments[0].top:void 0!==arguments[1]?arguments[1]:o.scrollY||o.pageYOffset))},o.scrollBy=function(){void 0!==arguments[0]&&(f(arguments[0])?i.scrollBy.call(o,void 0!==arguments[0].left?arguments[0].left:"object"!=typeof arguments[0]?arguments[0]:0,void 0!==arguments[0].top?arguments[0].top:void 0!==arguments[1]?arguments[1]:0):h.call(o,t.body,~~arguments[0].left+(o.scrollX||o.pageXOffset),~~arguments[0].top+(o.scrollY||o.pageYOffset)))},e.prototype.scroll=e.prototype.scrollTo=function(){if(void 0!==arguments[0])if(!0!==f(arguments[0])){var o=arguments[0].left,t=arguments[0].top;h.call(this,this,void 0===o?this.scrollLeft:~~o,void 0===t?this.scrollTop:~~t)}else{if("number"==typeof arguments[0]&&void 0===arguments[1])throw new SyntaxError("Value could not be converted");i.elementScroll.call(this,void 0!==arguments[0].left?~~arguments[0].left:"object"!=typeof arguments[0]?~~arguments[0]:this.scrollLeft,void 0!==arguments[0].top?~~arguments[0].top:void 0!==arguments[1]?~~arguments[1]:this.scrollTop)}},e.prototype.scrollBy=function(){void 0!==arguments[0]&&(!0!==f(arguments[0])?this.scroll({left:~~arguments[0].left+this.scrollLeft,top:~~arguments[0].top+this.scrollTop,behavior:arguments[0].behavior}):i.elementScroll.call(this,void 0!==arguments[0].left?~~arguments[0].left+this.scrollLeft:~~arguments[0]+this.scrollLeft,void 0!==arguments[0].top?~~arguments[0].top+this.scrollTop:~~arguments[1]+this.scrollTop))},e.prototype.scrollIntoView=function(){if(!0!==f(arguments[0])){var l=function(o){for(;o!==t.body&&!1===(e=p(l=o,"Y")&&a(l,"Y"),r=p(l,"X")&&a(l,"X"),e||r);)o=o.parentNode||o.host;var l,e,r;return o}(this),e=l.getBoundingClientRect(),r=this.getBoundingClientRect();l!==t.body?(h.call(this,l,l.scrollLeft+r.left-e.left,l.scrollTop+r.top-e.top),"fixed"!==o.getComputedStyle(l).position&&o.scrollBy({left:e.left,top:e.top,behavior:"smooth"})):o.scrollBy({left:r.left,top:r.top,behavior:"smooth"})}else i.scrollIntoView.call(this,void 0===arguments[0]||arguments[0])}}function n(o,t){this.scrollLeft=o,this.scrollTop=t}function f(o){if(null===o||"object"!=typeof o||void 0===o.behavior||"auto"===o.behavior||"instant"===o.behavior)return!0;if("object"==typeof o&&"smooth"===o.behavior)return!1;throw new TypeError("behavior member of ScrollOptions "+o.behavior+" is not a valid value for enumeration ScrollBehavior.")}function p(o,t){return"Y"===t?o.clientHeight+c<o.scrollHeight:"X"===t?o.clientWidth+c<o.scrollWidth:void 0}function a(t,l){var e=o.getComputedStyle(t,null)["overflow"+l];return"auto"===e||"scroll"===e}function d(t){var l,e,i,c,n=(s()-t.startTime)/r;c=n=n>1?1:n,l=.5*(1-Math.cos(Math.PI*c)),e=t.startX+(t.x-t.startX)*l,i=t.startY+(t.y-t.startY)*l,t.method.call(t.scrollable,e,i),e===t.x&&i===t.y||o.requestAnimationFrame(d.bind(o,t))}function h(l,e,r){var c,f,p,a,h=s();l===t.body?(c=o,f=o.scrollX||o.pageXOffset,p=o.scrollY||o.pageYOffset,a=i.scroll):(c=l,f=l.scrollLeft,p=l.scrollTop,a=n),d({scrollable:c,method:a,startTime:h,startX:f,startY:p,x:e,y:r})}}"object"==typeof exports&&"undefined"!=typeof module?module.exports={polyfill:o}:o()}();

if (location.href.toString().includes("youtube.com/embed")) {
    // Custom style
    let head = document.head;
    let css = document.createElement('style');
    css.type = "text/css";
    css.innerHTML = `
        .ytp-impression-link {
            display: none;
        }
        .ytp-pause-overlay {
            display: none;
        }
        .ytp-fullscreen-button {
            display: none !important;
        }
        .ytp-airplay-button {
            display: none !important;
        }
        .ytp-youtube-button {
            display: none !important;
        }
        .ytp-chrome-top-buttons {
            display: none;
        }
        .ytp-large-play-button {
            display: none;
        }
        .ytp-cued-thumbnail-overlay {
            display: none;
        }
        .iv-branding {
            display: none;
        }
    `
    head.appendChild(css);
} else if (location.href.toString().includes("youtube.com")) {
    // Fix for UIScrollView's aggressive scroll button placement
    // Set webView.scrollView.isScrollEnabled = false and use this code
    let isDown = false;
    let startY;
    let didScroll = false;
    window.addEventListener('touchstart', (e) => {
        isDown = true;
        startY = e.touches[0].clientY;
    });
    window.addEventListener('touchend', (e) => {
        isDown = false;
        // prevent unintentional clicking
        if (didScroll) {
            e.preventDefault()
            didScroll = false;
        }
    });
    window.addEventListener('touchmove', (e) => {
        if (!isDown) return;
        const y = e.touches[0].clientY;
        const walk = y - startY;
        if (walk > 10) {
            window.scrollBy({
              top: -(window.outerHeight / 2),
              behavior: 'smooth'
            })
            didScroll = true;
            isDown = false; // only scroll one at a time
        } else if (walk < -10) {
            window.scrollBy({
              top: (window.outerHeight / 2),
              behavior: 'smooth'
            })
            didScroll = true;
            isDown = false; // only scroll one at a time
        }
    });
    
    // URL change detect
    let previousUrl = '';
    const observer = new MutationObserver(function(mutations) {
        if (location.href !== previousUrl) {
            // Check if we're on a watch page
            const regex = /^(?:https?:\/\/)?(?:www\.)?(?:m\.|www\.|)(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))((\w|-){11})(?:\S+)?$/;
            if (regex.test(location.href)) {
                const id = location.href.match(regex)[1]
                window.open("https://www.youtube.com/embed/" + id)
            } else {
                previousUrl = location.href;
            }
        }
    });
    const config = {subtree: true, childList: true};
    observer.observe(document, config);
}

const isTextInput = el => el.tagName === "TEXTAREA" || (el.tagName === "INPUT" && (el.type === "text" || el.type === "email" || el.type === "search" || el.type === "url" || el.type === "password"));

// Focusing a text field
window.addEventListener("focus", e => {
    if (isTextInput(e.target)) {
        window.webkit.messageHandlers.keyboard.postMessage("show")
    }
}, true)

// Tapping a text field
window.addEventListener("click", e => {
    if (isTextInput(e.target)) {
        window.webkit.messageHandlers.keyboard.postMessage("show")
    }
}, true)

// Leaving a text field
window.addEventListener("blur", e => {
    if (isTextInput(e.target)) {
        window.webkit.messageHandlers.keyboard.postMessage("hide")
    }
}, true)

// Text field was selected on load
if (isTextInput(document.activeElement)) {
    window.webkit.messageHandlers.keyboard.postMessage("show")
}
