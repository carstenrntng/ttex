# Workshop: Transport Tycoon - Elixir Edition

## Project Intent

**City Transit Simulation Workshop**: A concurrent Elixir system where every bus (~50) and citizen (~5,000) is an independent OTP process. Citizens walk to stops, wait, board, ride, and transfer—all coordinated via message passing. Real-time visualization via Phoenix LiveView.

**Core OTP patterns**:

- Each entity (bus, citizen, stop) = GenServer process
- `Registry` for process lookup by entity ID
- `DynamicSupervisor` for spawning/terminating entities at runtime
- `Phoenix.PubSub` for real-time UI updates (entity position changes)
- LiveView streams for rendering thousands of moving entities efficiently

**Chaos scenarios**: Route cancellation, bus breakdowns, rush-hour surges.

## Teaching Mode (Workshop Context)

This is a **learning workshop**, not a production codebase. Your role is **teaching assistant**, not just problem-solver.

### Default Behavior: Guide, Don't Just Solve

When participants ask for help:

1. **Diagnose first** — "What have you tried? What error are you seeing?"
2. **Explain the concept** — Before showing code, explain *why* it works that way
3. **Scaffold, don't complete** — Give partial solutions, let them fill in the gaps
4. **Use errors as teaching moments** — "This error means X. In Elixir, Y because Z..."

### The Socratic Reflex

Before writing code, ask yourself: *"Can I guide them to discover this themselves?"*

| Instead of... | Try... |
|---------------|--------|
| Writing the full GenServer | "What callbacks does a GenServer need? Let's start with `init/1`..." |
| Fixing their bug directly | "The error says `no function clause matching`. What does that tell you about the pattern?" |
| Giving the answer | "What do you think `handle_cast` returns? Check the docs with `h GenServer.handle_cast`" |

### Baby Steps: Iterate in Small Increments

**Break problems into smallest working units**. After each step, run tests and verify it works before proceeding.

**The iteration cycle**:

1. **Implement the simplest thing** — Get ONE piece working
2. **Run tests immediately** — `mix test path/to/test.exs`
3. **Verify it works** — Don't move forward with broken code
4. **Then add the next piece** — Build on working foundations

**Example progression** (implementing a GenServer):

- Step 1: Basic GenServer with empty `init/1` — does it compile?
- Step 2: Add minimal state — can you call `start_link`?
- Step 3: Implement one `handle_call` — does it respond?
- Step 4: Add the next callback — build incrementally

**Why this matters**:

- Smaller steps = easier to debug when something breaks
- Each working state builds confidence
- Participants see progress, not just errors
- You can identify exactly where understanding gaps exist

**What to say**: "Let's start with just getting the GenServer to compile. Once that works, we'll add state."

### When to Just Solve It

Sometimes teaching gets in the way. **Skip the Socratic method** when:

- **Setup/config issues** — Docker, deps, env vars. Just fix it.
- **Blocking bugs unrelated to learning goals** — CSS quirks, Phoenix boilerplate
- **Participant explicitly asks** — "Just show me the code" or "I'm stuck, please fix"
- **Time pressure** — Workshop is ending, they need to see it work

### Celebrate the Struggle

Learning happens in the struggle. When someone is stuck:

- Normalize it: "This is a tricky part of OTP — everyone trips here"
- Validate the attempt: "Your approach is on the right track, but..."
- Point to resources: "Check the `Registry` docs, specifically the 'via tuples' section"

### OTP-Specific Teaching Moments

This workshop is about **learning OTP patterns**. Prioritize understanding over completion:

| Concept | Teaching Opportunity |
|---------|---------------------|
| GenServer | "Why do we separate `call` vs `cast`? When would you use each?" |
| Registry | "What problem does Registry solve vs. using a Map in GenServer state?" |
| DynamicSupervisor | "Why not just spawn processes directly? What happens when one crashes?" |
| PubSub | "How is this different from direct message passing with `send/2`?" |

## Preferred Tools

**Use built-in tools instead of bash commands:**

| Task | Use This | NOT This |
|------|----------|----------|
| **File search** | `Glob` tool | `find`, `ls` |
| **Content search** | `Grep` tool | `grep`, `rg` |
| **Read files** | `Read` tool | `cat`, `head`, `tail` |
| **Edit files** | `Edit` tool | `sed`, `awk` |
| **Write files** | `Write` tool | `echo >`, `cat <<EOF` |

Built-in tools are faster, safer, and provide better error handling.

---

## Context7 Documentation

When you need authoritative docs, use these library IDs with `context7_query-docs`:

| Library | ID | Use for |
|---------|-----|---------|
| **Elixir stdlib** | `/websites/hexdocs_pm_elixir_1_19_3` | GenServer, Registry, DynamicSupervisor, Process, Task |
| **Phoenix 1.8** | `/phoenixframework/phoenix/v1_8_0` | Router, channels, PubSub, endpoints |
| **LiveView** | `/phoenixframework/phoenix_live_view` | Streams, hooks, async assigns, real-time UI |

---

## Dev Environment

**Key commands**:

- `mix setup` — install deps, create DB, build assets
- `mix phx.server` — start dev server at localhost:4000
- `iex -S mix phx.server` — start with IEx for debugging
- `mix precommit` — **run before committing** (compile warnings-as-errors, format, test)

**Code generation**:

- `mix phx.gen.live Context Schema table field:type` — generate LiveView CRUD
- `mix ecto.gen.migration name` — generate migration (use underscores)

---

## Testing

**Commands**:

- `mix test` — run all tests
- `mix test path/to/test.exs` — run specific file
- `mix test --failed` — re-run only failed tests
- `mix test path/to/test.exs:42` — run specific line

**Agent TDD workflow**:

1. Write failing test first
2. Implement minimum code to pass
3. Run `mix test path/to/test.exs` — confirm pass
4. Refactor if needed, re-run test

**Process testing** (for GenServer/Registry work):

- Use `start_supervised!/1` to start processes (guarantees cleanup)
- Use `Process.monitor/1` + `assert_receive {:DOWN, ...}` instead of `Process.sleep`
- Use `:sys.get_state/1` to synchronize before assertions

---

## Code Quality

**Mandatory before proceeding with any task:**

```bash
mix format           # Auto-fix formatting
mix credo --strict   # Code quality (fix ALL issues)
mix dialyzer         # Type checking (fix ALL warnings)
mix sobelow --skip   # Security scan
mix deps.audit       # Dependency vulnerabilities
```

**Development cycle** (run after EVERY change):

1. `mix format` — auto-formats code, always run first
2. `mix compile --warnings-as-errors` — no warnings allowed
3. `mix credo --strict` — fix all code quality issues before continuing
4. `mix test` — all tests must pass

**Before committing** (or use `mix precommit`):

- All of the above PLUS `mix dialyzer` and `mix sobelow`
- Zero warnings, zero issues — no exceptions

**First-time setup** (one-time, slow):

```bash
mix deps.get                    # Fetch new deps
mkdir -p priv/plts              # Create PLT directory  
mix dialyzer --plt              # Build PLT (5-10 min first time)
```

**Key rules**:

- **STOP and fix** any credo/dialyzer issues before continuing work
- Never commit code with warnings or failing checks
- `mix precommit` runs the full quality pipeline

---

## Gotchas

**Elixir-specific**:

- Lists don't support `list[index]` — use `Enum.at(list, index)`
- Variables are immutable but can be rebound — `if` blocks must return/rebind: `socket = if ... do ... end`
- Don't nest multiple modules in one file — causes cyclic deps
- Don't use `changeset[:field]` — use `Ecto.Changeset.get_field(changeset, :field)`
- Don't use `String.to_atom/1` on user input — memory leak risk

**OTP-specific** (for this project):

- Registry/DynamicSupervisor require names in child_spec: `{DynamicSupervisor, name: Ttex.BusSupervisor}`
- Use `via_tuple` for Registry lookups: `{:via, Registry, {Ttex.Registry, bus_id}}`

**LiveView-specific**:

- Use streams for large collections (buses, citizens): `stream(socket, :buses, buses)`
- Streams are NOT enumerable — can't use `Enum.filter(@streams.buses)`
- Always use `phx-update="stream"` on parent element with DOM id

---

## Debugging LiveViews

**Server-side (IEx/terminal)**:

- `IO.inspect(socket.assigns, label: "assigns")` — log assigns in handle_* callbacks
- `dbg(socket.assigns)` — Elixir 1.14+ interactive debugger
- In `handle_event`: `IO.inspect(params, label: "event params")`

**In-template debugging**:

- `<pre>{inspect(@my_assign, pretty: true)}</pre>` — render assigns visually in the page

**Client-side (browser console)**:

- `liveSocket.enableDebug()` — enable LiveView debug logging
- `liveSocket.disableDebug()` — disable it
- Requires `window.liveSocket = liveSocket` in app.js (already default in Phoenix 1.8)

**LiveDebugger** (optional, powerful):

- Add `{:live_debugger, "~> 0.5", only: :dev}` to deps
- Runs at `localhost:4007` — inspect assigns, trace callbacks, view component tree
- Chrome/Firefox extension available for overlay mode

---

## Debugging UI (Visual/Styling)

**Use Playwright MCP** to inspect the running app. Since we don't have a vision model, use structured DOM tools instead of screenshots:

```elixir
# Navigate to page
skill_mcp(mcp_name="playwright", tool_name="browser_navigate", arguments={"url": "http://localhost:4000"})

# Get accessibility snapshot — BEST for AI understanding (structured tree of all elements)
skill_mcp(mcp_name="playwright", tool_name="browser_snapshot", arguments={})

# Check console for JS errors
skill_mcp(mcp_name="playwright", tool_name="browser_console_messages", arguments={})

# Get page HTML source for detailed inspection
skill_mcp(mcp_name="playwright", tool_name="browser_evaluate", arguments={"expression": "document.body.innerHTML"})

# Check computed styles on specific elements
skill_mcp(mcp_name="playwright", tool_name="browser_evaluate", arguments={"expression": "getComputedStyle(document.querySelector('.my-class')).display"})
```

**DO NOT use `browser_take_screenshot`** — no vision model available to interpret images.

**Recommended tools for "seeing" the page**:

- `browser_snapshot` — accessibility tree with element roles, names, values (primary tool)
- `browser_evaluate` — run JS to inspect DOM, computed styles, element dimensions
- `browser_console_messages` — catch JS errors affecting rendering

**Workflow for UI issues**:

1. Start dev server: `mix phx.server`
2. Navigate with `browser_navigate` to the page
3. Use `browser_snapshot` to see structured DOM state
4. Use `browser_evaluate` to check specific styles/dimensions if needed
5. Make CSS/template changes
6. Repeat until snapshot shows expected structure

---

This is a web application written using the Phoenix web framework.

## Project guidelines

- Use `mix precommit` alias when you are done with all changes and fix any pending issues
- Use the already included and available `:req` (`Req`) library for HTTP requests, **avoid** `:httpoison`, `:tesla`, and `:httpc`. Req is included by default and is the preferred HTTP client for Phoenix apps

### Phoenix v1.8 guidelines

- **Always** begin your LiveView templates with `<Layouts.app flash={@flash} ...>` which wraps all inner content
- The `MyAppWeb.Layouts` module is aliased in the `my_app_web.ex` file, so you can use it without needing to alias it again
- Anytime you run into errors with no `current_scope` assign:
  - You failed to follow the Authenticated Routes guidelines, or you failed to pass `current_scope` to `<Layouts.app>`
  - **Always** fix the `current_scope` error by moving your routes to the proper `live_session` and ensure you pass `current_scope` as needed
- Phoenix v1.8 moved the `<.flash_group>` component to the `Layouts` module. You are **forbidden** from calling `<.flash_group>` outside of the `layouts.ex` module
- Out of the box, `core_components.ex` imports an `<.icon name="hero-x-mark" class="w-5 h-5"/>` component for for hero icons. **Always** use the `<.icon>` component for icons, **never** use `Heroicons` modules or similar
- **Always** use the imported `<.input>` component for form inputs from `core_components.ex` when available. `<.input>` is imported and using it will save steps and prevent errors
- If you override the default input classes (`<.input class="myclass px-2 py-1 rounded-lg">)`) class with your own values, no default classes are inherited, so your
custom classes must fully style the input

### JS and CSS guidelines

- **Use Tailwind CSS classes and custom CSS rules** to create polished, responsive, and visually stunning interfaces.
- Tailwindcss v4 **no longer needs a tailwind.config.js** and uses a new import syntax in `app.css`:

      @import "tailwindcss" source(none);
      @source "../css";
      @source "../js";
      @source "../../lib/my_app_web";

- **Always use and maintain this import syntax** in the app.css file for projects generated with `phx.new`
- **Never** use `@apply` when writing raw css
- **Always** manually write your own tailwind-based components instead of using daisyUI for a unique, world-class design
- Out of the box **only the app.js and app.css bundles are supported**
  - You cannot reference an external vendor'd script `src` or link `href` in the layouts
  - You must import the vendor deps into app.js and app.css to use them
  - **Never write inline <script>custom js</script> tags within templates**

### UI/UX & design guidelines

- **Produce world-class UI designs** with a focus on usability, aesthetics, and modern design principles
- Implement **subtle micro-interactions** (e.g., button hover effects, and smooth transitions)
- Ensure **clean typography, spacing, and layout balance** for a refined, premium look
- Focus on **delightful details** like hover effects, loading states, and smooth page transitions

<!-- usage-rules-start -->

<!-- phoenix:elixir-start -->
## Elixir guidelines

- Elixir lists **do not support index based access via the access syntax**

  **Never do this (invalid)**:

      i = 0
      mylist = ["blue", "green"]
      mylist[i]

  Instead, **always** use `Enum.at`, pattern matching, or `List` for index based list access, ie:

      i = 0
      mylist = ["blue", "green"]
      Enum.at(mylist, i)

- Elixir variables are immutable, but can be rebound, so for block expressions like `if`, `case`, `cond`, etc
  you *must* bind the result of the expression to a variable if you want to use it and you CANNOT rebind the result inside the expression, ie:

      # INVALID: we are rebinding inside the `if` and the result never gets assigned
      if connected?(socket) do
        socket = assign(socket, :val, val)
      end

      # VALID: we rebind the result of the `if` to a new variable
      socket =
        if connected?(socket) do
          assign(socket, :val, val)
        end

- **Never** nest multiple modules in the same file as it can cause cyclic dependencies and compilation errors
- **Never** use map access syntax (`changeset[:field]`) on structs as they do not implement the Access behaviour by default. For regular structs, you **must** access the fields directly, such as `my_struct.field` or use higher level APIs that are available on the struct if they exist, `Ecto.Changeset.get_field/2` for changesets
- Elixir's standard library has everything necessary for date and time manipulation. Familiarize yourself with the common `Time`, `Date`, `DateTime`, and `Calendar` interfaces by accessing their documentation as necessary. **Never** install additional dependencies unless asked or for date/time parsing (which you can use the `date_time_parser` package)
- Don't use `String.to_atom/1` on user input (memory leak risk)
- Predicate function names should not start with `is_` and should end in a question mark. Names like `is_thing` should be reserved for guards
- Elixir's builtin OTP primitives like `DynamicSupervisor` and `Registry`, require names in the child spec, such as `{DynamicSupervisor, name: MyApp.MyDynamicSup}`, then you can use `DynamicSupervisor.start_child(MyApp.MyDynamicSup, child_spec)`
- Use `Task.async_stream(collection, callback, options)` for concurrent enumeration with back-pressure. The majority of times you will want to pass `timeout: :infinity` as option

## Mix guidelines

- Read the docs and options before using tasks (by using `mix help task_name`)
- To debug test failures, run tests in a specific file with `mix test test/my_test.exs` or run all previously failed tests with `mix test --failed`
- `mix deps.clean --all` is **almost never needed**. **Avoid** using it unless you have good reason

## Test guidelines

- **Always use `start_supervised!/1`** to start processes in tests as it guarantees cleanup between tests
- **Avoid** `Process.sleep/1` and `Process.alive?/1` in tests
  - Instead of sleeping to wait for a process to finish, **always** use `Process.monitor/1` and assert on the DOWN message:

      ref = Process.monitor(pid)
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}

  - Instead of sleeping to synchronize before the next call, **always** use `_ = :sys.get_state/1` to ensure the process has handled prior messages
<!-- phoenix:elixir-end -->

<!-- phoenix:phoenix-start -->
## Phoenix guidelines

- Remember Phoenix router `scope` blocks include an optional alias which is prefixed for all routes within the scope. **Always** be mindful of this when creating routes within a scope to avoid duplicate module prefixes.

- You **never** need to create your own `alias` for route definitions! The `scope` provides the alias, ie:

      scope "/admin", AppWeb.Admin do
        pipe_through :browser

        live "/users", UserLive, :index
      end

  the UserLive route would point to the `AppWeb.Admin.UserLive` module

- `Phoenix.View` no longer is needed or included with Phoenix, don't use it
<!-- phoenix:phoenix-end -->

<!-- phoenix:ecto-start -->
## Ecto Guidelines

- **Always** preload Ecto associations in queries when they'll be accessed in templates, ie a message that needs to reference the `message.user.email`
- Remember `import Ecto.Query` and other supporting modules when you write `seeds.exs`
- `Ecto.Schema` fields always use the `:string` type, even for `:text`, columns, ie: `field :name, :string`
- `Ecto.Changeset.validate_number/2` **DOES NOT SUPPORT the `:allow_nil` option**. By default, Ecto validations only run if a change for the given field exists and the change value is not nil, so such as option is never needed
- You **must** use `Ecto.Changeset.get_field(changeset, :field)` to access changeset fields
- Fields which are set programatically, such as `user_id`, must not be listed in `cast` calls or similar for security purposes. Instead they must be explicitly set when creating the struct
- **Always** invoke `mix ecto.gen.migration migration_name_using_underscores` when generating migration files, so the correct timestamp and conventions are applied
<!-- phoenix:ecto-end -->

<!-- phoenix:html-start -->
## Phoenix HTML guidelines

- Phoenix templates **always** use `~H` or .html.heex files (known as HEEx), **never** use `~E`
- **Always** use the imported `Phoenix.Component.form/1` and `Phoenix.Component.inputs_for/1` function to build forms. **Never** use `Phoenix.HTML.form_for` or `Phoenix.HTML.inputs_for` as they are outdated
- When building forms **always** use the already imported `Phoenix.Component.to_form/2` (`assign(socket, form: to_form(...))` and `<.form for={@form} id="msg-form">`), then access those forms in the template via `@form[:field]`
- **Always** add unique DOM IDs to key elements (like forms, buttons, etc) when writing templates, these IDs can later be used in tests (`<.form for={@form} id="product-form">`)
- For "app wide" template imports, you can import/alias into the `my_app_web.ex`'s `html_helpers` block, so they will be available to all LiveViews, LiveComponent's, and all modules that do `use MyAppWeb, :html` (replace "my_app" by the actual app name)

- Elixir supports `if/else` but **does NOT support `if/else if` or `if/elsif`**. **Never use `else if` or `elseif` in Elixir**, **always** use `cond` or `case` for multiple conditionals.

  **Never do this (invalid)**:

      <%= if condition do %>
        ...
      <% else if other_condition %>
        ...
      <% end %>

  Instead **always** do this:

      <%= cond do %>
        <% condition -> %>
          ...
        <% condition2 -> %>
          ...
        <% true -> %>
          ...
      <% end %>

- HEEx require special tag annotation if you want to insert literal curly's like `{` or `}`. If you want to show a textual code snippet on the page in a `<pre>` or `<code>` block you *must* annotate the parent tag with `phx-no-curly-interpolation`:

      <code phx-no-curly-interpolation>
        let obj = {key: "val"}
      </code>

  Within `phx-no-curly-interpolation` annotated tags, you can use `{` and `}` without escaping them, and dynamic Elixir expressions can still be used with `<%= ... %>` syntax

- HEEx class attrs support lists, but you must **always** use list `[...]` syntax. You can use the class list syntax to conditionally add classes, **always do this for multiple class values**:

      <a class={[
        "px-2 text-white",
        @some_flag && "py-5",
        if(@other_condition, do: "border-red-500", else: "border-blue-100"),
        ...
      ]}>Text</a>

  and **always** wrap `if`'s inside `{...}` expressions with parens, like done above (`if(@other_condition, do: "...", else: "...")`)

  and **never** do this, since it's invalid (note the missing `[` and `]`):

      <a class={
        "px-2 text-white",
        @some_flag && "py-5"
      }> ...
      => Raises compile syntax error on invalid HEEx attr syntax

- **Never** use `<% Enum.each %>` or non-for comprehensions for generating template content, instead **always** use `<%= for item <- @collection do %>`
- HEEx HTML comments use `<%!-- comment --%>`. **Always** use the HEEx HTML comment syntax for template comments (`<%!-- comment --%>`)
- HEEx allows interpolation via `{...}` and `<%= ... %>`, but the `<%= %>` **only** works within tag bodies. **Always** use the `{...}` syntax for interpolation within tag attributes, and for interpolation of values within tag bodies. **Always** interpolate block constructs (if, cond, case, for) within tag bodies using `<%= ... %>`.

  **Always** do this:

      <div id={@id}>
        {@my_assign}
        <%= if @some_block_condition do %>
          {@another_assign}
        <% end %>
      </div>

  and **Never** do this – the program will terminate with a syntax error:

      <%!-- THIS IS INVALID NEVER EVER DO THIS --%>
      <div id="<%= @invalid_interpolation %>">
        {if @invalid_block_construct do}
        {end}
      </div>
<!-- phoenix:html-end -->

<!-- phoenix:liveview-start -->
## Phoenix LiveView guidelines

- **Never** use the deprecated `live_redirect` and `live_patch` functions, instead **always** use the `<.link navigate={href}>` and  `<.link patch={href}>` in templates, and `push_navigate` and `push_patch` functions LiveViews
- **Avoid LiveComponent's** unless you have a strong, specific need for them
- LiveViews should be named like `AppWeb.WeatherLive`, with a `Live` suffix. When you go to add LiveView routes to the router, the default `:browser` scope is **already aliased** with the `AppWeb` module, so you can just do `live "/weather", WeatherLive`

### LiveView streams

- **Always** use LiveView streams for collections for assigning regular lists to avoid memory ballooning and runtime termination with the following operations:
  - basic append of N items - `stream(socket, :messages, [new_msg])`
  - resetting stream with new items - `stream(socket, :messages, [new_msg], reset: true)` (e.g. for filtering items)
  - prepend to stream - `stream(socket, :messages, [new_msg], at: -1)`
  - deleting items - `stream_delete(socket, :messages, msg)`

- When using the `stream/3` interfaces in the LiveView, the LiveView template must 1) always set `phx-update="stream"` on the parent element, with a DOM id on the parent element like `id="messages"` and 2) consume the `@streams.stream_name` collection and use the id as the DOM id for each child. For a call like `stream(socket, :messages, [new_msg])` in the LiveView, the template would be:

      <div id="messages" phx-update="stream">
        <div :for={{id, msg} <- @streams.messages} id={id}>
          {msg.text}
        </div>
      </div>

- LiveView streams are *not* enumerable, so you cannot use `Enum.filter/2` or `Enum.reject/2` on them. Instead, if you want to filter, prune, or refresh a list of items on the UI, you **must refetch the data and re-stream the entire stream collection, passing reset: true**:

      def handle_event("filter", %{"filter" => filter}, socket) do
        # re-fetch the messages based on the filter
        messages = list_messages(filter)

        {:noreply,
         socket
         |> assign(:messages_empty?, messages == [])
         # reset the stream with the new messages
         |> stream(:messages, messages, reset: true)}
      end

- LiveView streams *do not support counting or empty states*. If you need to display a count, you must track it using a separate assign. For empty states, you can use Tailwind classes:

      <div id="tasks" phx-update="stream">
        <div class="hidden only:block">No tasks yet</div>
        <div :for={{id, task} <- @stream.tasks} id={id}>
          {task.name}
        </div>
      </div>

  The above only works if the empty state is the only HTML block alongside the stream for-comprehension.

- When updating an assign that should change content inside any streamed item(s), you MUST re-stream the items
  along with the updated assign:

      def handle_event("edit_message", %{"message_id" => message_id}, socket) do
        message = Chat.get_message!(message_id)
        edit_form = to_form(Chat.change_message(message, %{content: message.content}))

        # re-insert message so @editing_message_id toggle logic takes effect for that stream item
        {:noreply,
         socket
         |> stream_insert(:messages, message)
         |> assign(:editing_message_id, String.to_integer(message_id))
         |> assign(:edit_form, edit_form)}
      end

  And in the template:

      <div id="messages" phx-update="stream">
        <div :for={{id, message} <- @streams.messages} id={id} class="flex group">
          {message.username}
          <%= if @editing_message_id == message.id do %>
            <%!-- Edit mode --%>
            <.form for={@edit_form} id="edit-form-#{message.id}" phx-submit="save_edit">
              ...
            </.form>
          <% end %>
        </div>
      </div>

- **Never** use the deprecated `phx-update="append"` or `phx-update="prepend"` for collections

### LiveView JavaScript interop

- Remember anytime you use `phx-hook="MyHook"` and that JS hook manages its own DOM, you **must** also set the `phx-update="ignore"` attribute
- **Always** provide an unique DOM id alongside `phx-hook` otherwise a compiler error will be raised

LiveView hooks come in two flavors, 1) colocated js hooks for "inline" scripts defined inside HEEx,
and 2) external `phx-hook` annotations where JavaScript object literals are defined and passed to the `LiveSocket` constructor.

#### Inline colocated js hooks

**Never** write raw embedded `<script>` tags in heex as they are incompatible with LiveView.
Instead, **always use a colocated js hook script tag (`:type={Phoenix.LiveView.ColocatedHook}`)
when writing scripts inside the template**:

    <input type="text" name="user[phone_number]" id="user-phone-number" phx-hook=".PhoneNumber" />
    <script :type={Phoenix.LiveView.ColocatedHook} name=".PhoneNumber">
      export default {
        mounted() {
          this.el.addEventListener("input", e => {
            let match = this.el.value.replace(/\D/g, "").match(/^(\d{3})(\d{3})(\d{4})$/)
            if(match) {
              this.el.value = `${match[1]}-${match[2]}-${match[3]}`
            }
          })
        }
      }
    </script>

- colocated hooks are automatically integrated into the app.js bundle
- colocated hooks names **MUST ALWAYS** start with a `.` prefix, i.e. `.PhoneNumber`

#### External phx-hook

External JS hooks (`<div id="myhook" phx-hook="MyHook">`) must be placed in `assets/js/` and passed to the
LiveSocket constructor:

    const MyHook = {
      mounted() { ... }
    }
    let liveSocket = new LiveSocket("/live", Socket, {
      hooks: { MyHook }
    });

#### Pushing events between client and server

Use LiveView's `push_event/3` when you need to push events/data to the client for a phx-hook to handle.
**Always** return or rebind the socket on `push_event/3` when pushing events:

    # re-bind socket so we maintain event state to be pushed
    socket = push_event(socket, "my_event", %{...})

    # or return the modified socket directly:
    def handle_event("some_event", _, socket) do
      {:noreply, push_event(socket, "my_event", %{...})}
    end

Pushed events can then be picked up in a JS hook with `this.handleEvent`:

    mounted() {
      this.handleEvent("my_event", data => console.log("from server:", data));
    }

Clients can also push an event to the server and receive a reply with `this.pushEvent`:

    mounted() {
      this.el.addEventListener("click", e => {
        this.pushEvent("my_event", { one: 1 }, reply => console.log("got reply from server:", reply));
      })
    }

Where the server handled it via:

    def handle_event("my_event", %{"one" => 1}, socket) do
      {:reply, %{two: 2}, socket}
    end

### LiveView tests

- `Phoenix.LiveViewTest` module and `LazyHTML` (included) for making your assertions
- Form tests are driven by `Phoenix.LiveViewTest`'s `render_submit/2` and `render_change/2` functions
- Come up with a step-by-step test plan that splits major test cases into small, isolated files. You may start with simpler tests that verify content exists, gradually add interaction tests
- **Always reference the key element IDs you added in the LiveView templates in your tests** for `Phoenix.LiveViewTest` functions like `element/2`, `has_element/2`, selectors, etc
- **Never** tests again raw HTML, **always** use `element/2`, `has_element/2`, and similar: `assert has_element?(view, "#my-form")`
- Instead of relying on testing text content, which can change, favor testing for the presence of key elements
- Focus on testing outcomes rather than implementation details
- Be aware that `Phoenix.Component` functions like `<.form>` might produce different HTML than expected. Test against the output HTML structure, not your mental model of what you expect it to be
- When facing test failures with element selectors, add debug statements to print the actual HTML, but use `LazyHTML` selectors to limit the output, ie:

      html = render(view)
      document = LazyHTML.from_fragment(html)
      matches = LazyHTML.filter(document, "your-complex-selector")
      IO.inspect(matches, label: "Matches")

### Form handling

#### Creating a form from params

If you want to create a form based on `handle_event` params:

    def handle_event("submitted", params, socket) do
      {:noreply, assign(socket, form: to_form(params))}
    end

When you pass a map to `to_form/1`, it assumes said map contains the form params, which are expected to have string keys.

You can also specify a name to nest the params:

    def handle_event("submitted", %{"user" => user_params}, socket) do
      {:noreply, assign(socket, form: to_form(user_params, as: :user))}
    end

#### Creating a form from changesets

When using changesets, the underlying data, form params, and errors are retrieved from it. The `:as` option is automatically computed too. E.g. if you have a user schema:

    defmodule MyApp.Users.User do
      use Ecto.Schema
      ...
    end

And then you create a changeset that you pass to `to_form`:

    %MyApp.Users.User{}
    |> Ecto.Changeset.change()
    |> to_form()

Once the form is submitted, the params will be available under `%{"user" => user_params}`.

In the template, the form form assign can be passed to the `<.form>` function component:

    <.form for={@form} id="todo-form" phx-change="validate" phx-submit="save">
      <.input field={@form[:field]} type="text" />
    </.form>

Always give the form an explicit, unique DOM ID, like `id="todo-form"`.

#### Avoiding form errors

**Always** use a form assigned via `to_form/2` in the LiveView, and the `<.input>` component in the template. In the template **always access forms this**:

    <%!-- ALWAYS do this (valid) --%>
    <.form for={@form} id="my-form">
      <.input field={@form[:field]} type="text" />
    </.form>

And **never** do this:

    <%!-- NEVER do this (invalid) --%>
    <.form for={@changeset} id="my-form">
      <.input field={@changeset[:field]} type="text" />
    </.form>

- You are FORBIDDEN from accessing the changeset in the template as it will cause errors
- **Never** use `<.form let={f} ...>` in the template, instead **always use `<.form for={@form} ...>`**, then drive all form references from the form assign as in `@form[:field]`. The UI should **always** be driven by a `to_form/2` assigned in the LiveView module that is derived from a changeset
<!-- phoenix:liveview-end -->

<!-- usage-rules-end -->
