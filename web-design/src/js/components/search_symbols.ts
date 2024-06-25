// In the future implement fuzzy search using libraries such as `fuse.js`

const searchInput = document.getElementById("sidebar-search")! as HTMLInputElement;
const navTreeContainer = document.getElementById("navigation-tree-container")!;

const listItems = navTreeContainer.querySelectorAll("li");
searchInput.addEventListener("input", () => {
  const query = searchInput.value
  window.localStorage.setItem('search-query', query)
  search(query)
});

// Apply saved query
let query = window.localStorage.getItem('search-query')
if(query) {
  searchInput.value = query
  search(query)
}

function search(query: string) {
  if(query.length === 0) {
    listItems.forEach(li => {
      li.removeAttribute("forced-visible");
      (li as any).style.display = null;
    });
    return;
  }
  // case-insensitive fuzzy search
  const regexp = new RegExp(".*"+query.split("").map(escapeRegExp).join(".*")+".*", "i");

  listItems.forEach(li => {
    const text = li.textContent ?? "";
    const anyChildMatches = descendantEntries(text).some(entry => regexp.test(entry))
    if (anyChildMatches) {
      (li as any).style.display = null;
      li.setAttribute("forced-visible", "true");
      let parent = li.parentElement;
      while (parent && parent !== navTreeContainer) {
        if (parent.tagName === "LI") {
          (parent as any).style.display = null;
        }
        parent = parent.parentElement;
      }
    } else {
      li.removeAttribute("forced-visible");
      li.style.display = "none";
    }
  });
}

/// The text is separated by newlines, and there might be a lot of additional spaces and whitespaces around them.
function descendantEntries(text: string) {
  return text
    .split("\n")
    .map(line => line.trim())
    .filter(line => line.length > 0);
}
function escapeRegExp(string: string) {
  return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
