# Transport Tycoon Workshop Handout

## Core Concept

Build a **concurrent city transit simulation** where every bus (~50) and citizen (~5,000) is an independent OTP process. Citizens walk, wait, board, ride, and transfer—all via message passing. Real-time visualization with Phoenix LiveView.

## Workshop Progression

### **Step 1: The Simple Bus GenServer**

Build a single bus that holds x/y coordinates and can move.

**Key Concepts:**

- GenServer basics: state, `call` vs `cast`, `init/1`
- Client API vs server callbacks
- Why separate them? (concurrency safety)

**Try:** Start a bus, move it, check its state

### **Step 2: Supervised Named Process**

Add the bus to the supervision tree with an atom name.

**Key Concepts:**

- Supervision = automatic restart on crash
- Named processes with atoms
- Process restarts lose state (fresh `init/1`)

**Try:** Crash the bus, watch it restart with fresh state

### **Step 3: The Scaling Problem** ⚠️

**Designed failure:** Try to add 50 buses with atom names.

**Why It Breaks:**

- Manual setup is tedious (list every bus)
- Atoms never garbage collected → memory leak risk
- Can't add/remove buses at runtime
- No dynamic behavior

**Key Insight:** Need DynamicSupervisor + Registry + via tuples

### **Step 4: DynamicSupervisor**

Spawn/stop buses at runtime instead of hardcoding them.

**Key Concepts:**

- `DynamicSupervisor.start_child/2` for runtime spawning
- `which_children/1` to list running processes
- Still tracking PIDs manually (awkward)

**Try:** Start/stop buses dynamically, list all buses

### **Step 5: Registry + Via Tuples**

Map custom IDs (strings) to PIDs without atoms.

**Key Concepts:**

- Registry = phone book (ID → PID)
- Via tuples: `{:via, Registry, {Ttex.Registry, "bus-1"}}`
- GenServer uses via tuples for name resolution
- `keys: :unique` enforces uniqueness

**Try:** Look up buses by string ID, move them without tracking PIDs

### **Step 6: Seed 50 Buses at Startup**

Now that infrastructure exists, spawning 50 buses is trivial.

**Key Concepts:**

- Create `Ttex.Seeds.seed_buses/1`
- Call after supervision tree starts
- Random initial positions

**Try:** List all 50 buses, move a specific one by ID

## Common Pitfalls

❌ **Registry after DynamicSupervisor** → Buses can't register  
✅ Start Registry before DynamicSupervisor

❌ **`String.to_atom/1` for IDs** → Memory leak  
✅ Use Registry via tuples with strings

❌ **Not handling `{:already_started, pid}`** → Crashes on duplicate start  
✅ Pattern match both `{:ok, pid}` and `{:error, {:already_started, pid}}`

---

## Debugging Tips

```elixir
# See all registered processes
Registry.select(Ttex.Registry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2"}}]}])

# Count children
DynamicSupervisor.count_children(Ttex.BusSupervisor)

# Trace messages
{:ok, pid} = Ttex.Buses.get_bus("bus-1")
:sys.trace(pid, true)
Ttex.Bus.move_to("bus-1", 5, 5)  # Watch messages print
```
