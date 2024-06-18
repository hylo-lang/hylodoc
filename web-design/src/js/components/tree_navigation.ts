document.getElementById('navigation-tree-container')?.querySelectorAll('li').forEach(el => {
    let entry =  el.querySelector('& > a.nav-entry')
    if(!entry) return

    let href = entry.getAttribute('href')
    if(href != document.location.pathname) return

    el.classList.add('active')
})