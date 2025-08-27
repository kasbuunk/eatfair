# Debug Component Crashes - LiveView Troubleshooting Guide

*Comprehensive debugging prompt for LiveView component crashes, function clause errors, and user interface issues. Based on successful resolution of critical location search keyboard navigation bug.*

---

## 🎯 **PROMPT ACTIVATION**

**One-liner Usage**: 
```
Use DEBUG_COMPONENT_CRASHES.md to systematically debug and fix the following component crash: [YOUR_SPECIFIC_ERROR]
```

**Full Debugging Session**:
```
Activate comprehensive LiveView component debugging workflow from DEBUG_COMPONENT_CRASHES.md for: [DETAILED_ERROR_DESCRIPTION]
```

---

## 📋 **SYSTEMATIC DEBUGGING FRAMEWORK**

### **PHASE 1: ERROR IDENTIFICATION & LOG ANALYSIS**

#### 1.1 Check Application Logs FIRST
**Location**: `log/eatfair_dev.log` (or appropriate log file for your environment)
```bash
tail -100 log/eatfair_dev.log
```

**Critical Information to Extract**:
- **Error Type**: `FunctionClauseError`, `ArgumentError`, `MatchError`, etc.
- **Exact Function**: Which `handle_event/3`, `handle_info/2`, or other function failed
- **Parameters Received**: What specific parameters caused the crash
- **Stack Trace**: Full call stack showing where error originated
- **Process Information**: LiveView process ID and state information

#### 1.2 Identify Crash Patterns
Look for:
- **Repeated Errors**: Same error pattern occurring multiple times
- **Parameter Variations**: Different parameter combinations causing same error
- **User Actions**: What user interactions trigger the crash
- **Timing Issues**: When during user interaction the crash occurs

### **PHASE 2: ROOT CAUSE ANALYSIS**

#### 2.1 Function Clause Analysis
For `FunctionClauseError` (most common):
- **Missing Function Clauses**: Check if component handles all possible event parameters
- **Parameter Format Changes**: Verify expected vs. actual parameter structure
- **Catch-all Clauses**: Determine if catch-all handlers are needed
- **Pattern Matching**: Ensure patterns match actual incoming data

#### 2.2 Component Event Flow Analysis
- **Event Sources**: Where are events coming from (browser, parent components, etc.)
- **Event Types**: What types of events does component need to handle
- **Parameter Structure**: What parameter formats are being received
- **Expected vs. Actual**: Compare expected parameters with what's actually arriving

### **PHASE 3: REPRODUCTION STRATEGY**

#### 3.1 Create Failing Test First (TDD Approach)
```elixir
@tag :focus
test "REPRODUCES CRASH: [specific scenario]" do
  # Reproduce exact error conditions from logs
  {:ok, lv, _html} = live(conn, "/target-page")
  
  # Reproduce exact user action that causes crash
  assert_raise FunctionClauseError, ~r/no function clause matching/, fn ->
    lv
    |> element("[test-selector]") 
    |> render_keydown(%{"key" => "h", "value" => ""}) # Use exact params from logs
  end
end
```

#### 3.2 Test Multiple Scenarios
- **Single Character Input**: Test individual key presses
- **Modifier Key Combinations**: Test Ctrl+key, Meta+key, Alt+key combinations
- **International Characters**: Test Unicode input if applicable
- **Edge Case Inputs**: Test empty strings, special characters, long inputs

### **PHASE 4: SYSTEMATIC FIX IMPLEMENTATION**

#### 4.1 Add Catch-All Handlers (Most Common Fix)
```elixir
# Add catch-all clause to prevent FunctionClauseError
@impl true
def handle_event("problematic_event", _params, socket) do
  # Graceful handling of unexpected parameters
  # Log unexpected parameters for future analysis if needed
  {:noreply, socket}
end
```

#### 4.2 Enhance Parameter Validation
```elixir
@impl true
def handle_event("event_name", params, socket) do
  case params do
    %{"key" => key, "value" => value} when is_binary(key) and is_binary(value) ->
      # Handle expected format
      handle_specific_key_input(key, value, socket)
    
    %{"key" => key} when is_binary(key) ->
      # Handle key-only events
      handle_key_only(key, socket)
    
    _other ->
      # Graceful fallback for unexpected formats
      {:noreply, socket}
  end
end
```

### **PHASE 5: COMPREHENSIVE VALIDATION**

#### 5.1 Test All Input Scenarios
```elixir
test "handles all keyboard input gracefully" do
  {:ok, lv, _html} = live(conn, "/target-page")
  
  # Test comprehensive input matrix
  input_scenarios = [
    # Regular typing
    %{"key" => "a", "value" => ""},
    %{"key" => "1", "value" => "a"},
    # Modifier combinations  
    %{"key" => "Meta", "value" => "a"},
    %{"key" => "Ctrl", "value" => "c"},
    # Special characters
    %{"key" => " ", "value" => "test "},
    %{"key" => "ñ", "value" => "niño"},
    # Navigation keys (should still work)
    %{"key" => "ArrowDown"},
    %{"key" => "Enter"},
    %{"key" => "Tab"},
    %{"key" => "Escape"}
  ]
  
  for scenario <- input_scenarios do
    # Each should work without crashing
    result = lv
    |> element("[test-selector]")
    |> render_keydown(scenario)
    
    assert is_binary(result), "Input #{inspect(scenario)} should not crash"
  end
end
```

#### 5.2 Regression Prevention Testing
- **Comprehensive Input Matrix**: Test wide variety of input combinations
- **Boundary Conditions**: Test edge cases and unusual inputs
- **Performance Impact**: Ensure fixes don't negatively impact performance
- **Existing Functionality**: Verify all existing features still work correctly

---

## 🔍 **COMMON CRASH PATTERNS & SOLUTIONS**

### Pattern 1: Keyboard Navigation FunctionClauseError
**Symptoms**: Users typing causes "Something went wrong! attempting to reconnect"
**Root Cause**: Component handles specific navigation keys but not regular typing
**Solution**: Add catch-all clause for keyboard_navigation events

```elixir
@impl true  
def handle_event("keyboard_navigation", _params, socket) do
  # Catch-all for any keyboard input not specifically handled
  {:noreply, socket}
end
```

### Pattern 2: Parameter Structure Mismatch
**Symptoms**: Component expects certain parameter format but receives different structure
**Root Cause**: Frontend sends different parameters than component expects
**Solution**: Flexible parameter handling with pattern matching

```elixir
@impl true
def handle_event("event_name", params, socket) do
  case params do
    %{"expected_key" => value} -> handle_expected(value, socket)
    %{"alternative_key" => value} -> handle_alternative(value, socket)
    _other -> {:noreply, socket} # Graceful fallback
  end
end
```

### Pattern 3: Missing Event Handlers
**Symptoms**: New events added to frontend but no backend handler
**Root Cause**: Frontend/backend synchronization issue
**Solution**: Add handlers for all events that frontend can generate

---

## 🚀 **DEBUGGING WORKFLOW CHECKLIST**

### Investigation Phase
- [ ] Check application logs for exact error details
- [ ] Identify specific function and parameters causing crash
- [ ] Determine user actions that trigger the error
- [ ] Analyze frequency and pattern of crashes

### Reproduction Phase  
- [ ] Create failing test that reproduces exact crash
- [ ] Test multiple input scenarios that might cause similar issues
- [ ] Verify crash is consistently reproducible
- [ ] Document exact steps to reproduce

### Fix Implementation Phase
- [ ] Implement catch-all handlers or parameter validation
- [ ] Add graceful error handling for edge cases
- [ ] Ensure fix doesn't break existing functionality
- [ ] Test fix resolves original crash

### Validation Phase
- [ ] Run original failing test to confirm it now passes
- [ ] Add comprehensive regression tests
- [ ] Test wide variety of input scenarios
- [ ] Verify all existing functionality still works
- [ ] Check application logs for any new errors

### Documentation Phase
- [ ] Document root cause and solution in commit messages
- [ ] Update component documentation with parameter requirements
- [ ] Add comments explaining any non-obvious error handling
- [ ] Create backlog item if broader pattern fixes are needed

---

## 📊 **SUCCESS CRITERIA FOR CRASH RESOLUTION**

### Technical Success Indicators
- [ ] **Zero Crashes**: All user input scenarios work without LiveView crashes
- [ ] **Graceful Handling**: Unexpected parameters handled gracefully without errors
- [ ] **Functional Preservation**: All existing component functionality remains intact
- [ ] **Performance Maintained**: No performance degradation from added error handling

### User Experience Success Indicators  
- [ ] **Smooth Interaction**: Users can interact with component without errors
- [ ] **No Error Messages**: No "Something went wrong" messages during normal use
- [ ] **Expected Behavior**: Component behaves as users expect for all input types
- [ ] **Reliability**: Component handles all reasonable user interaction patterns

### Quality Engineering Success Indicators
- [ ] **Comprehensive Tests**: All crash scenarios covered by automated tests
- [ ] **Regression Prevention**: Test suite prevents similar crashes in future
- [ ] **Clear Documentation**: Debugging approach documented for future reference
- [ ] **Pattern Recognition**: Similar issues across codebase identified and addressed

---

## 🔗 **INTEGRATION WITH EXISTING WORKFLOWS**

### Test-Driven Development Integration
1. **Red**: Create failing test reproducing exact crash from logs
2. **Green**: Implement minimal fix to make test pass (usually catch-all handler)
3. **Refactor**: Add comprehensive input validation and testing

### Quality Assurance Integration
- **Use VALIDATE_ALL_TESTS_PASS.md** for comprehensive component analysis
- **Reference PROCESS_FEEDBACK.md** for user-reported crash issues
- **Follow TDD workflow from development process documentation

### Documentation Integration
- **Update PROJECT_IMPLEMENTATION.md** with crash resolution details
- **Create or update component documentation** with parameter requirements
- **Document debugging process** for future team reference

---

## 🎪 **EXAMPLE SUCCESS STORY**

### Case Study: AddressAutocomplete Keyboard Navigation Crash

**Problem**: Users experienced "Something went wrong! attempting to reconnect" errors when typing in location search field after 5 previous failed attempts to resolve the issue.

**Root Cause**: `FunctionClauseError` in `handle_event("keyboard_navigation", params, socket)` - component handled specific navigation keys (`ArrowDown`, `ArrowUp`, `Enter`, `Tab`, `Escape`) but had no handler for regular typing characters like `"h"`, `"a"`, etc.

**Solution**: Added catch-all clause:
```elixir
@impl true
def handle_event("keyboard_navigation", _params, socket) do
  # Catch-all clause for any keyboard input that isn't navigation
  # This prevents FunctionClauseError crashes when users type regular characters
  # Regular typing should be handled by input_change event, not keyboard_navigation
  {:noreply, socket}
end
```

**Validation**: Created comprehensive test suite covering 30+ keyboard input combinations including international characters and modifier keys.

**Result**: Location search now works smoothly without crashes, achieving the requested Google Maps-like experience.

---

*This debugging framework provides a systematic approach to identifying, reproducing, fixing, and preventing LiveView component crashes. Use it whenever users report interaction errors or when you encounter FunctionClauseError patterns in your application.*
