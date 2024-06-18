// Search me up like one of your french girls
// In the future implement fuzzy search using libraries such as `fuse.js`
const searchInput = document.getElementById("sidebar-search") as HTMLInputElement;
const navTreeContainer = document.getElementById("navigation-tree-container");

if (searchInput && navTreeContainer) {
  searchInput.addEventListener("input", () => {
    const query = searchInput.value.toLowerCase();
    const items = navTreeContainer.querySelectorAll("li");

    items.forEach(item => {
      const text = item.textContent?.toLowerCase() || "";
      if (text.includes(query)) {
        item.style.display = "block";
        let parent = item.parentElement;
        while (parent && parent !== navTreeContainer) {
          if (parent.tagName === "UL" || parent.tagName === "LI") {
            (parent as HTMLElement).style.display = "block";
          }
          parent = parent.parentElement;
        }
      } else {
        item.style.display = "none";
      }
    });
  });
}
