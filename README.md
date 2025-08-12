# 🚀 Sui Move Educational Samples

> **⚠️ EDUCATIONAL & DEMONSTRATION PURPOSES ONLY**: These samples are created exclusively for learning and demonstration purposes. They are **NOT production-ready** and should never be used in live applications without significant modifications, proper error handling, and comprehensive security audits.

A collection of educational Sui Move smart contracts demonstrating core concepts and patterns unique to the Sui blockchain ecosystem. Perfect for developers transitioning from other Move implementations (like Aptos) or those new to Sui development.

## 🎯 What's Inside

### 📦 Sample Modules

This repository contains various Move modules showcasing different Sui concepts:
- **Multi-module interactions** - Cross-module communication and object lifecycle management
- **Access control patterns** - Object-based permissions and capability systems
- **Data structure operations** - Vector handling and basic object manipulation
- **And more...** - Additional samples will be added over time

### 🧪 Test Suite

Each module comes with comprehensive tests demonstrating usage patterns and edge cases for educational purposes.

## 🔄 Sui Move vs Aptos Move: Key Differences

Coming from Aptos Move? Here are the major differences you'll encounter in these samples:

### Object Model
```move
// ❌ Aptos: Resources stored in global storage
move_to(&signer, MyResource { ... });

// ✅ Sui: Objects with unique identifiers transferred explicitly
transfer::transfer(MyObject { id: object::new(ctx), ... }, recipient);
```

### Transaction Context
```move
// ❌ Aptos: Access signer from global context
fun my_function() acquires MyResource {
    let signer_addr = signer::address_of(&signer);
}

// ✅ Sui: Context passed as parameter
fun my_function(ctx: &mut TxContext) {
    let sender = tx_context::sender(ctx);
}
```

## 📋 Sui Move Object Abilities Reference Table

| Capability | `key` | `store` | `copy` | `drop` | `key + store` | `key + drop` | `store + copy` | All Four |
|------------|-------|---------|--------|--------|---------------|--------------|----------------|----------|
| **Can be a top-level object** | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ |
| **Can be stored inside other objects** | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | ✅ | ✅ |
| **Can be copied/duplicated** | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ |
| **Auto-destroyed when unused** | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ | ✅ |
| **Can use `transfer::transfer()`** | ✅* | ❌ | ❌ | ❌ | ✅* | ✅* | ❌ | ✅* |
| **Can use `transfer::public_transfer()`** | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ |
| **Can be transferred by external modules** | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ |
| **Must be explicitly handled** | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| **Can have global storage** | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ |
| **Requires UID field** | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ |

### Legend:
- ✅ = Yes/Allowed
- ❌ = No/Not Allowed  
- \* = Only by the defining module

### Individual Ability Breakdown:

#### `key` Only
```move
public struct MyStruct has key {
    id: UID,
    // ... other fields
}
```
- **Can be stored as top-level object**: ✅ Yes
- **Can be copied**: ❌ No (UID prevents copying)
- **Storable in objects**: ❌ No
- **Can be transferred by external modules**: ❌ No (only defining module)
- **Can use public_transfer**: ❌ No
- **Auto-destroyed**: ❌ No (must be explicitly handled)

#### `store` Only
```move
public struct MyStruct has store {
    // ... fields (no UID)
}
```
- **Can be stored as top-level object**: ❌ No
- **Can be copied**: ❌ No (unless all fields have copy)
- **Storable in objects**: ✅ Yes
- **Can be transferred by external modules**: ❌ No (not a top-level object)
- **Can use public_transfer**: ❌ No (needs key)
- **Auto-destroyed**: ❌ No (must be explicitly handled)

#### `copy` Only
```move
public struct MyStruct has copy {
    value: u64,  // All fields must have copy
}
```
- **Can be stored as top-level object**: ❌ No
- **Can be copied**: ✅ Yes
- **Storable in objects**: ✅ Yes (copy implies store-like behavior)
- **Can be transferred by external modules**: ❌ No (not a top-level object)
- **Can use public_transfer**: ❌ No (needs key)
- **Auto-destroyed**: ❌ No (unless also has drop)

#### `drop` Only
```move
public struct MyStruct has drop {
    // ... fields (all must have drop)
}
```
- **Can be stored as top-level object**: ❌ No
- **Can be copied**: ❌ No
- **Storable in objects**: ✅ Yes (drop implies store-like behavior)
- **Can be transferred by external modules**: ❌ No (not a top-level object)
- **Can use public_transfer**: ❌ No (needs key)
- **Auto-destroyed**: ✅ Yes

#### `key + store` (Most Common for Transferable Objects)
```move
public struct MyStruct has key, store {
    id: UID,
    // ... other fields
}
```
- **Can be stored as top-level object**: ✅ Yes
- **Can be copied**: ❌ No (UID prevents copying)
- **Storable in objects**: ✅ Yes
- **Can be transferred by external modules**: ✅ Yes (via public_transfer)
- **Can use public_transfer**: ✅ Yes
- **Auto-destroyed**: ❌ No (must be explicitly handled)


### Object Access Patterns
```move
// ❌ Aptos: Global borrowing from storage
fun read_data(): String acquires MyResource {
    let resource = borrow_global<MyResource>(@user);
    resource.data
}

fun modify_data() acquires MyResource {
    let resource = borrow_global_mut<MyResource>(@user);
    resource.data = string::utf8(b"new value");
}

// ✅ Sui: Objects passed as function parameters
fun read_data(obj: &MyObject): String {
    obj.data  // Read-only access via reference
}

fun modify_data(obj: &mut MyObject) {
    obj.data = string::utf8(b"new value");  // Mutable access via mutable reference
}

fun transfer_object(obj: MyObject, recipient: address) {
    transfer::transfer(obj, recipient);  // Transfer ownership (consumes object)
}
```

**Key Differences:**
- **Aptos**: Uses `borrow_global` and `borrow_global_mut` to access resources from global storage
- **Sui**: Objects are explicitly passed as function parameters:
  - `*param*: &MyObject` - Read-only access (immutable reference)
  - `*param*: &mut MyObject` - Mutable access for editing
  - `mut *param*: MyObject` - Mutable access for editing(accessible with &mut) and object operations(transfer, delete, ...)
  - `*param*: MyObject` - Object operations only(transfer, delete, ...)

### Transfer Patterns
- **Aptos**: Resources live in account storage, accessed via global operators
- **Sui**: Objects are explicitly transferred between addresses or made shared

## 🏗️ Project Structure

```
sui_samples/
├── sources/                       # Move modules with educational examples
│   └── *.move                     # Various Sui Move samples
├── tests/                         # Comprehensive test suites
│   └── *_tests.move              # Test files for each module
├── Move.toml                      # Package configuration
└── Move.lock                      # Dependency lock file
```

## 🚀 Getting Started

### Prerequisites
- [Sui CLI](https://docs.sui.io/build/install) installed
- Basic understanding of Move language concepts

### Build & Test
```bash
# Build the project
sui move build

# Run all tests
sui move test

# Run specific test module (example)
sui move test --filter <module_name>_tests
```

### Deploy to Testnet
```bash
# Deploy to Sui testnet
sui client publish --gas-budget 20000000
```

## 🤝 Contributing

Found an issue or want to improve the educational content? PRs are welcome! Please ensure:
- Code remains educational and well-commented for demonstration purposes
- Tests cover new functionality with clear educational examples
- Documentation is updated accordingly
- All contributions maintain the educational/demonstration focus

## 📖 Resources

- [Sui Documentation](https://docs.sui.io/)
- [Move Language Reference](https://move-language.github.io/move/)
- [Sui Move by Example](https://examples.sui.io/)

---

**Happy Learning! 🎉**

*Remember: All samples in this repository are for educational and demonstration purposes only. They prioritize clarity and learning over production optimization.*