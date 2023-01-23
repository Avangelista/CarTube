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
