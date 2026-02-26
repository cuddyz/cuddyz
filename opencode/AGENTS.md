# OpenCode Global Rules — cuddyz

This is the global `AGENTS.md` for all opencode sessions on this machine.
It lives at `~/.config/opencode/AGENTS.md` (symlinked from this repo).

---

## SSH & GitHub Identity

This machine has **two GitHub accounts** configured via separate SSH keys and
`~/.ssh/config` host aliases. Always use the correct remote alias when cloning,
setting remotes, or pushing.

| Account | SSH Host Alias | Key File | Use For |
|---|---|---|---|
| cuddyz | `git@github.com-cuddyz` | `~/.ssh/id_rsa` | Personal repos (github.com/cuddyz) |
| ChromeDomeWebDesigns | `git@github.com-cdwd` | `~/.ssh/cdwd_id_rsa` | CDWD client/business repos |

### Rules

- When cloning a **cuddyz** repo, always use:
  `git clone git@github.com-cuddyz:cuddyz/<repo>.git`
- When cloning a **ChromeDomeWebDesigns** repo, always use:
  `git clone git@github.com-cdwd:ChromeDomeWebDesigns/<repo>.git`
- Never use the bare `git@github.com:` host directly — it will use the wrong key.
- After cloning, verify the remote with `git remote -v` and update if the wrong
  host alias was used.
- When setting up a new repo for cuddyz:
  `git remote set-url origin git@github.com-cuddyz:cuddyz/<repo>.git`
- When setting up a new repo for ChromeDomeWebDesigns:
  `git remote set-url origin git@github.com-cdwd:ChromeDomeWebDesigns/<repo>.git`

### SSH Config (reference)

```
# Personal
Host github.com-cuddyz
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa

# CDWD
Host github.com-cdwd
    HostName github.com
    User git
    IdentityFile ~/.ssh/cdwd_id_rsa
```

---

## Sounds

Peon-ping is installed with the **zelda-mix** pack (OOT + A Link to the Past).
Config lives at `~/.config/opencode/peon-ping/config.json`.

---

## General Conventions

- Platform: macOS (darwin)
- Shell: bash/zsh
- Package manager preference: Homebrew where available, then npm/bun
- Prefer editing existing files over creating new ones
- Commit only when explicitly asked
- No force pushes to main/master without explicit confirmation

---

## Nuxt 2 Development Style

Reference project: `ChromeDomeWebDesigns/planet-overstock-wholesale`
(locally at `~/Documents/Projects/planet-overstock-wholesale`)

This section defines the preferred patterns for all Nuxt 2 / Vue 2 projects. Weight
these conventions above general Vue/Nuxt community defaults.

---

### Architecture Overview

- **Target:** `static` (SSG via `nuxt generate`) hosted on Netlify. Prefer this
  unless the project explicitly requires SSR.
- **Data layer:** Firestore (Firebase v9 modular SDK) for persistence; Firebase
  Storage for file uploads; Firebase Auth (email/password only) for admin access.
- **Plugin system:** Firebase is initialized as a plain ES module (`plugins/firebase.js`)
  that exports named service instances (`db`, `auth`, `storage`). It is registered
  in `nuxt.config.js` as `mode: 'universal'`; client-only plugins (facets prefetch,
  cookie hydration, third-party directives) are registered as `mode: 'client'`.

**Reference files:**
- `nuxt.config.js` — plugin registration order, module list, `generate.routes()`
- `plugins/firebase.js` — canonical Firebase init pattern
- `plugins/facets.js` — parallel prefetch on app boot with `Promise.all`
- `plugins/cookies.js` — store hydration from cookie on page load

---

### Directory & File Conventions

```
pages/         → Nuxt file-system routing; _param.vue for dynamic routes
components/    → Organized by domain subdirectory (home/, inventory/, admin/)
layouts/       → One layout per auth context (default, admin, admin-login)
store/         → One Vuex module file per domain; no store/index.js
plugins/       → One concern per file; named clearly by what it does
lib/           → Pure JS helpers: constants.js, utils.js, seo.js, domain enums
assets/styles/ → SCSS partials, imported in app.scss
```

Dynamic routes use the `_id.vue` naming convention for Nuxt 2 (NOT `[id].vue`
which is Nuxt 3 syntax).

---

### Component Structure (Options API — always)

This codebase is 100% Options API. Do not use Composition API (`setup()`, `ref()`,
`reactive()`, `computed` from Vue 3) in Nuxt 2 projects.

The canonical key order inside `export default {}`:

```js
export default {
  name: 'ComponentName',
  components: { ... },
  props: { ... },
  data() { return { ... } },
  head() { ... },         // pages only — use headBuilder from lib/seo.js
  computed: {
    ...mapState('module', ['key']),
    ...mapGetters({ localName: 'module/getterName' }),
    // local computed properties below
  },
  watch: { ... },
  created() { ... },      // preferred lifecycle hook for data fetching
  methods: {
    ...mapActions({ localName: 'module/actionName' }),
    // local methods below
  },
}
```

**Static option data (avoid making large arrays reactive):**
Attach static lookup arrays directly to the options object rather than returning
them from `data()`. Access via `$options.arrayName` in the template:
```js
export default {
  inventorySortOptionsArray,   // NOT in data() — avoids reactivity overhead
  costMeasurementOptionsArray,
  ...
}
```

**Reference:** `components/admin/inventory/AdminInventoryForm.vue`

---

### Naming Conventions

| Thing | Convention | Example |
|---|---|---|
| Component files | PascalCase | `InventoryCard.vue` |
| Component tags in templates | kebab-case | `<inventory-card>` |
| Vuex mutations | SCREAMING_SNAKE_CASE | `LOAD_INVENTORY` |
| Vuex actions / getters | camelCase | `fetchInventory`, `getInventoryItemById` |
| SCSS class names | kebab-case | `.inventory-card`, `.card-header` |
| JS variables / methods | camelCase | `formData`, `tryToSaveItem` |
| Constants | SCREAMING_SNAKE_CASE | `PAGE_SIZE`, `AUTH_COOKIE` |
| Firestore document IDs | snake_case (via `toSnakeCase()` from `lib/utils.js`) | |

---

### Vuex Patterns

- **Always use helper maps** — never access `$store` directly in components.
- Store modules are namespaced by filename (Nuxt auto-imports `store/*.js`).
- Cross-module dispatches from within the store use `{ root: true }`:
  ```js
  dispatch('facets/updateFacetCount', payload, { root: true })
  ```
- Getters that find by ID use the curried function pattern:
  ```js
  getInventoryItemById: state => (itemId) => state.inventory.find(i => i.id === itemId)
  ```
- Use a **counting semaphore** (`loadingCounter`) rather than a boolean when
  multiple async actions can run concurrently in the same module:
  ```js
  // store/facets.js — loadingCounter increments per in-flight request
  isLoading: state => state.loadingCounter > 0
  ```

**Reference:** `store/inventory.js`, `store/facets.js`, `store/users.js`

---

### Async & Error Handling

- **`async/await` everywhere** in store actions.
- **`Promise.all()`** for concurrent independent async operations (image URL
  resolution, facet prefetch):
  ```js
  await Promise.all(facets.map(facet => store.dispatch('facets/fetchSearchFacetItems', { facet })))
  ```
- Store actions follow `try/catch/finally` with loading state in `finally`:
  ```js
  async fetchInventory({ commit }, payload) {
    try {
      commit('UPDATE_LOADING', true)
      // ... Firebase calls
    } catch (e) {
      console.error(e)
    } finally {
      commit('UPDATE_LOADING', false)
    }
  }
  ```
- Components surface errors via local `error` data property + `<error-banner>`:
  ```js
  // in page method
  try {
    await this.addInventoryItem(payload)
    this.$router.push('/admin/inventory')
  } catch {
    this.error = 'Item already exists with that ID.'
  }
  ```
- **No validation library.** Form validation is imperative guard-clause style
  inside a `tryToSaveItem()` method that returns early on failure and sets
  `this.error`. See `components/admin/inventory/AdminInventoryForm.vue`.

---

### Firebase Usage Rules

- **Firebase is never called directly from components.** All Firestore / Storage /
  Auth calls live in `store/` action files.
- Import service instances from the plugin file:
  ```js
  import { db, storage, auth } from '@/plugins/firebase'
  ```
- Use the **Firebase v9 modular SDK** syntax (`collection`, `query`, `where`,
  `getDocs`, `setDoc`, `updateDoc`, `deleteDoc`, `serverTimestamp`, `increment`,
  `ref`, `uploadBytes`, `getDownloadURL`, etc.).
- Use `increment()` for atomic counter updates on facet counts — never read-
  modify-write for counters.
- **Optimistic deletes:** commit the removal to the store immediately, then delete
  from Firestore. Do not wait for the round-trip before updating UI.

**Reference:** `store/inventory.js` (private helper functions `rebuildSSR`,
`buildInventoryQuery`, `fetchImageURLs`, `uploadImages`, `deleteImages`)

---

### SCSS Style

The SCSS system is built around three foundational `@function` + map patterns.
Always use these functions — **never hardcode hex values, px breakpoints, or font
families** in component SCSS.

```scss
color('primary')          // @import '@/assets/styles/colors'
breaks(tablet)            // @import '@/assets/styles/breaks'
font('body')              // @import '@/assets/styles/fonts'
```

Import only the partials a component needs at the top of its `<style>` block:
```scss
<style lang="scss" scoped>
@import './assets/styles/colors';
@import './assets/styles/breaks';
```
(Paths are relative from the component file back to `assets/`.)

- **No BEM.** Use descriptive kebab-case class names with SCSS nesting that mirrors
  the HTML structure.
- **`scoped` by default.** Only omit `scoped` when you need styles to reach into
  child components (e.g., wrapping grid components).
- **Mobile-first responsive:** `@media (min-width: breaks(tablet))` inside component
  scoped styles.
- **Hover states:** `lighten(color('primary'), 10%)` and `rgba(color('primary'), 0.15)`
  for tinted backgrounds.

**Reference:** `assets/styles/_colors.scss`, `assets/styles/_breaks.scss`,
`components/inventory/InventoryCard.vue` (typical component SCSS),
`layouts/admin.vue` (CSS Grid layout with breakpoint)

---

### Forms

- `formData` is always a **deep clone** of the prop:
  `JSON.parse(JSON.stringify(this.item))` — not a direct reference.
- All fields bind via `v-model` to `formData.*`.
- Submit is triggered by `@click` on the button AND `@submit.prevent` on the
  form. The button click calls the validation method, which emits `save` on
  success.
- For computed `v-model` on a child component that must emit changes upward, use
  a computed setter:
  ```js
  search: {
    get() { return this.searchValue },
    set(val) { this.$emit('updateSearch', val) }
  }
  ```
- **Debounce** search inputs with `lodash.debounce` at `DEBOUNCE_MS` (250ms from
  `lib/constants.js`). Define debounced methods as method properties (not inside
  another method) using `function` keyword so `this` binds to the component:
  ```js
  methods: {
    debounceSearch: debounce(function () {
      this.refetchData()
    }, DEBOUNCE_MS)
  }
  ```

---

### Routing & Navigation

- `this.$router.push('/path')` — programmatic navigation after form saves/deletes.
- `<nuxt-link>` — all declarative links in templates.
- `this.$route.params.id` — access dynamic route params.
- **`asyncData`** is used only when data must be server-rendered (e.g., public
  inventory detail page). All other pages fetch in `created()`.
- **Layout assignment** goes on the page component:
  ```js
  layout: 'admin'        // protected pages
  layout: 'admin-login'  // login page (redirect away if already authed)
  // omit for default layout
  ```
- Auth guard logic lives in the **layout**, not middleware. Use a local `auth`
  boolean + `created()` check with `$router.push` redirect.

**Reference:** `layouts/admin.vue`, `pages/inventory/_id.vue` (asyncData),
`pages/admin/inventory/index.vue` (created + mapActions pattern)

---

### lib/ — Shared Logic

Keep all shareable non-reactive logic in `lib/`:

| File | Contents |
|---|---|
| `lib/constants.js` | App-wide string/number constants, `SEARCH_FACETS` mapping object |
| `lib/inventoryItems.js` | Domain enums, sort options, default item template |
| `lib/utils.js` | Pure functions: `prettyNumber`, `toSnakeCase`, `formatBytes`, `paginate` |
| `lib/seo.js` | `headBuilder()` — call in every page's `head()` method |

No mixins. Extract shared logic into `lib/` helpers instead.
