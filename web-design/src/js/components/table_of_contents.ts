// Table of Content
const tableOfContents = Array.from(document.querySelectorAll(".page-toc a"))
    .filter(tag => tag.getAttribute('href')!.startsWith("#"))
    .map(tag => {
        let sectionId = tag.getAttribute('href')!.substring(1)
        let section = document.getElementById(sectionId)!
        return {
            tag: tag.parentElement!,
            section: section
        }
    })

// Update table of content while scrolling
let activeSection: HTMLElement = tableOfContents[0].tag
activeSection.classList.add('active')

document.querySelector('.page-body')!.addEventListener('scroll', () => {
    let inRange = tableOfContents.filter(item => {
        const rec = item.section.getBoundingClientRect()
        return rec.top <= 65 && rec.bottom > 0
    }).sort((a, b) => {
        let recA = a.section.getBoundingClientRect()
        let recB = b.section.getBoundingClientRect()

        return recB.top - recA.bottom
    })
    if(inRange.length == 0)
        return

    let item = inRange[0]
    if(activeSection == item.tag)
        return

    if(activeSection != null)
        activeSection.classList.remove('active')

    activeSection = item.tag
    activeSection.classList.add('active')
})