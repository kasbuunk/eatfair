# CRITICAL BUG: Location Search Causing LiveView Crashes

## Status
#status/done

## Priority
🔴 **CRITICAL** - Production Blocker - Must fix immediately

## Issue Description

### What's Happening
- Users experience flickering "Something went wrong! attempting to reconnect" errors when typing in location search
- Any keyboard input (letters like 'h', 'a', etc.) causes the LiveView to crash and reconnect
- Location search is completely broken - users cannot enter addresses
- After 5 previous chat iterations, this remains unresolved

### Expected Behavior
**Google Maps-like Experience Required:**
- As user types, show real-time address suggestions
- User can press Enter to accept top suggestion
- User can click on any suggestion to select it
- User can navigate suggestions with arrow keys
- Graceful handling of all keyboard input
- No crashes or connection errors
- Smooth, responsive UX

### Technical Root Cause
`FunctionClauseError` in `EatfairWeb.Live.Components.AddressAutocomplete.handle_event/3`:
```
** (FunctionClauseError) no function clause matching in EatfairWeb.Live.Components.AddressAutocomplete.handle_event/3
```

The component handles specific keys (`ArrowDown`, `ArrowUp`, `Enter`, `Tab`, `Escape`) but has no catch-all clause for regular typing characters, causing crashes when users type letters.

### User Impact
- **ALL users cannot use location search**
- **Core restaurant discovery journey is broken**
- **Users abandon the platform due to crashes**
- **5 expensive development iterations with no resolution**

## Solution Requirements

### Immediate Fix Needed
1. **Add catch-all clause** for keyboard_navigation event to prevent crashes
2. **Ensure input_change event handles typing properly**
3. **Test all keyboard interactions thoroughly**
4. **Add comprehensive regression tests**

### UX Requirements  
1. **Real-time suggestions** as user types (minimum 2 characters)
2. **Keyboard navigation** with arrow keys
3. **Enter to select** top suggestion
4. **Click to select** any suggestion
5. **Graceful error handling** - no crashes ever
6. **Performance** - smooth, responsive typing

## Implementation Plan

### Phase 1: Critical Bug Fix (Immediate) ✅ COMPLETED
- [x] Add catch-all keyboard_navigation handler
- [x] Write failing test reproducing the crash
- [x] Fix the component to handle all keyboard input
- [x] Verify no crashes occur during typing

### Phase 2: Complete Solution (Next)
- [ ] Ensure address suggestions work properly
- [ ] Test entire location search flow end-to-end
- [ ] Add comprehensive test coverage
- [ ] Validate Google Maps-like UX experience

## Acceptance Criteria
- [ ] User can type in location field without any crashes
- [ ] Real-time address suggestions appear as user types
- [ ] All keyboard navigation works (arrows, Enter, Tab, Escape)
- [ ] Click selection works on all suggestions
- [ ] No "Something went wrong" errors occur
- [ ] Smooth, responsive typing experience
- [ ] Comprehensive test coverage prevents regression

## Test Cases to Cover
1. **Typing regular characters** (a, b, c, etc.) - should not crash
2. **Typing with modifier keys** (Meta+h, Ctrl+a, etc.) - should not crash
3. **Arrow key navigation** through suggestions
4. **Enter key selection** of highlighted suggestion
5. **Click selection** of any suggestion
6. **Tab completion** to first suggestion
7. **Escape to close** suggestions
8. **Focus and blur events**
9. **Empty input handling**
10. **Network error handling** for suggestions

## Log Evidence
```
** (FunctionClauseError) no function clause matching in EatfairWeb.Live.Components.AddressAutocomplete.handle_event/3
Parameters: %{"key" => "h", "value" => ""}
Parameters: %{"key" => "Meta", "value" => "h"}
```

This shows the component receives all keyboard events but only handles specific navigation keys, causing crashes on regular typing.

## Development Notes
- Location: `lib/eatfair_web/live/components/address_autocomplete.ex:31`
- Error logs: `log/eatfair_dev.log` 
- This is the **#1 priority** - platform is unusable without working location search
- User frustration is extremely high after multiple failed attempts
