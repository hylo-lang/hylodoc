let navigationContainer = document.getElementById('navigation-tree-container')
let navigationItems = navigationContainer?.querySelectorAll('li')

navigationItems?.forEach(el => {
    const entry =  el.querySelector('& > a.nav-entry')
    if(!entry) return

    // Set active entry
    const href = entry.getAttribute('href')
    if(href === document.location.pathname) el.classList.add('active')

    // Find checkbox if element has children
    const checkbox = el.querySelector('& > input[type="checkbox"]') as HTMLInputElement
    if(!checkbox) return

    // Load collapsed state from persistence
    const state = window.localStorage.getItem("nav-entry@"+href)
    const collapsed = state !== 'true'

    // Toggle collapsed state
    if(collapsed) {
        checkbox.removeAttribute('checked')
    } else {
        checkbox.setAttribute('checked', '')
    }

    // Store state
    checkbox.addEventListener('change', () => {
        const collapsed = !checkbox.checked
        window.localStorage.setItem("nav-entry@"+href, collapsed ? 'false' : 'true')
    })
})