# Elixir Language Guidelines

Tags: #elixir #language #patterns

*Elixir-specific language patterns, conventions, and best practices for effective functional programming.*

## Language Fundamentals

### Data Structure Access
- Elixir lists **do not support index based access via the access syntax**

  **Never do this (invalid)**:

      i = 0
      mylist = ["blue", "green"]
      mylist[i]

  Instead, **always** use `Enum.at`, pattern matching, or `List` for index based list access, ie:

      i = 0
      mylist = ["blue", "green"]
      Enum.at(mylist, i)

### Variable Binding and Immutability
- Elixir variables are immutable, but can be rebound, so for block expressions like `if`, `case`, `cond`, etc you *must* bind the result of the expression to a variable if you want to use it and you CANNOT rebind the result inside the expression, ie:

      # INVALID: we are rebinding inside the `if` and the result never gets assigned
      if connected?(socket) do
        socket = assign(socket, :val, val)
      end

      # VALID: we rebind the result of the `if` to a new variable
      socket =
        if connected?(socket) do
          assign(socket, :val, val)
        end

### Module and Struct Guidelines
- **Never** nest multiple modules in the same file as it can cause cyclic dependencies and compilation errors
- **Never** use map access syntax (`changeset[:field]`) on structs as they do not implement the Access behaviour by default. For regular structs, you **must** access the fields directly, such as `my_struct.field` or use higher level APIs that are available on the struct if they exist, `Ecto.Changeset.get_field/2` for changesets

### Date and Time Handling
- Elixir's standard library has everything necessary for date and time manipulation. Familiarize yourself with the common `Time`, `Date`, `DateTime`, and `Calendar` interfaces by accessing their documentation as necessary. **Never** install additional dependencies unless asked or for date/time parsing (which you can use the `date_time_parser` package)

### Security Considerations
- Don't use `String.to_atom/1` on user input (memory leak risk)

### Function Naming Conventions
- Predicate function names should not start with `is_` and should end in a question mark. Names like `is_thing` should be reserved for guards

### OTP and Process Management
- Elixir's builtin OTP primitives like `DynamicSupervisor` and `Registry`, require names in the child spec, such as `{DynamicSupervisor, name: MyApp.MyDynamicSup}`, then you can use `DynamicSupervisor.start_child(MyApp.MyDynamicSup, child_spec)`

### Concurrent Processing
- Use `Task.async_stream(collection, callback, options)` for concurrent enumeration with back-pressure. The majority of times you will want to pass `timeout: :infinity` as option

## Pattern Matching

### Best Practices
- Use pattern matching instead of conditionals when possible
- Pattern match on function parameters for clearer intent
- Use guard clauses for simple type checking
- Prefer pattern matching over accessing struct fields in conditionals

### Common Patterns
```elixir
# Pattern match on function parameters
def handle_event("save", %{"user" => user_params}, socket) do
  # Implementation
end

# Pattern match on case statements
case create_user(params) do
  {:ok, user} -> handle_success(user)
  {:error, changeset} -> handle_error(changeset)
end

# Use guards for type checking
def process_data(data) when is_list(data) do
  # Implementation for lists
end

def process_data(data) when is_map(data) do
  # Implementation for maps
end
```

## Error Handling

### Elixir Error Patterns
- Use tagged tuples `{:ok, result}` and `{:error, reason}` for operations that can fail
- Let processes crash and restart rather than defensive programming
- Use `with` statements for chaining operations that can fail
- Handle errors at appropriate boundaries, not everywhere

### Example Error Handling
```elixir
# Using with for error handling chain
with {:ok, user} <- get_user(id),
     {:ok, account} <- get_account(user),
     {:ok, result} <- perform_operation(account) do
  {:ok, result}
else
  {:error, reason} -> {:error, reason}
end
```

## Performance Considerations

### Efficient Data Processing
- Use `Enum.reduce` instead of `Enum.map` when accumulating values
- Use streams for large data sets that don't fit in memory
- Prefer tail-recursive functions for large iterations
- Use `Enum.into` for efficient data structure conversions

### Memory Management
- Be aware of process memory usage in long-running processes
- Use binary pattern matching for string processing
- Avoid creating large intermediate data structures unnecessarily

## Testing Patterns

### ExUnit Best Practices
- Use descriptive test names that explain the scenario
- Group related tests using `describe` blocks
- Use `setup` and `setup_all` for test data preparation
- Test both success and failure paths
- Use pattern matching in assertions for clearer error messages

### Example Test Structure
```elixir
defmodule MyModuleTest do
  use ExUnit.Case

  describe "create_user/1" do
    test "creates user with valid params" do
      params = %{name: "John", email: "john@example.com"}
      
      assert {:ok, user} = MyModule.create_user(params)
      assert user.name == "John"
      assert user.email == "john@example.com"
    end

    test "returns error with invalid params" do
      params = %{name: "", email: "invalid"}
      
      assert {:error, changeset} = MyModule.create_user(params)
      assert changeset.errors[:name]
      assert changeset.errors[:email]
    end
  end
end
```

---

*These Elixir patterns ensure code is idiomatic, maintainable, and leverages the language's strengths in concurrency, fault tolerance, and functional programming.*
