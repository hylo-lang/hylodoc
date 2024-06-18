// Copy to clipboard
document.querySelectorAll(".code-snippet").forEach(el => {
    // find code-block in code-snippet
    let code = el.querySelector('code')

    // ignore code-snippets without code section
    if(code == null)
        return;

    // copy code
    let copy = el.querySelector('.copy')
    if(copy != null) {
        copy.addEventListener('click', () => {
            navigator.clipboard.writeText(code.innerText)
            console.log('copied code-snippet to clipboard')
        })
    }

    // Other button actions?
})