// module world::transport;

// use world::request::{Self, Request};
// use world::requirement::Requirement;
// use sui::table::{Self, Table};
// use std::type_name::{Self, TypeName};
// use std::internal;
// use world::structure::{Self, Structure, OwnerCap};
// use world::admin_acl::AdminACL;

// public struct TransportConfig has key, store {
//     id: UID,
//     requirements: Table<TypeName, vector<Requirement>>,
// }

// // These are firmware modules that can be attached to a structure to provide additional functionality
// public struct Transport has store {
//     structure_id: ID, // use parent structure id
//     // Both of these are per action requirements in the transport module
//     // This will be executed on top of the parent structure requirements
//     default_requirements: Table<TypeName, vector<Requirement>>,
//     custom_requirements: Table<TypeName, vector<Requirement>>, // can be renamed
// }

// #[error(code = 0)]
// const ENotAuthorized: vector<u8> = b"Not authorized";

// public struct Jump()

// public fun attach(structure: &mut Structure, admin_acl: &AdminACL, ctx: &mut TxContext) {
//     let transport = Transport {
//         structure_id: object::id(structure),
//         default_requirements: table::new(ctx),
//         custom_requirements: table::new(ctx),
//     };
//     structure::attach_module<Transport>(structure, admin_acl, internal::permit<Transport>(), transport, ctx);
// }

// // === Actions ===

// public fun jump(structure: &Structure, _ctx: &mut TxContext): Request {
//     let transport = structure.module_state<Transport>(internal::permit<Transport>());
//     let mut requires = requirements<Jump>(&transport.default_requirements);
//     requires.append(requirements<Jump>(&transport.custom_requirements));

//     request::new(b"transport:jump".to_string(), option::some(object::id(structure)), requires)
// }

// // === Rules Addition and Removal ===

// public fun add_default_requirement<A>(
//     structure: &mut Structure,
//     admin_acl: &AdminACL,
//     r: Requirement,
//     ctx: &TxContext,
// ) {
//     assert!(admin_acl.is_authorized_address(ctx.sender()), ENotAuthorized);
//     let transport = structure.module_state_mut<Transport>(internal::permit<Transport>());
//     push(&mut transport.default_requirements, type_name::with_original_ids<A>(), r);
// }

// public fun add_custom_requirement<A>(
//     structure: &mut Structure,
//     owner_cap: &OwnerCap,
//     r: Requirement,
//     ctx: &TxContext,
// ) {
//     let transport = structure.module_state_mut<Transport>(internal::permit<Transport>());
//     push(&mut transport.custom_requirements, type_name::with_original_ids<A>(), r);
// }


// fun requirements<A>(req: &Table<TypeName, vector<Requirement>>): vector<Requirement> {
//     let key = type_name::with_original_ids<A>();
//     if (req.contains(key)) *req.borrow(key)
//     else vector[]
// }

// fun push(
//     table: &mut Table<TypeName, vector<Requirement>>,
//     key: TypeName,
//     r: Requirement,
// ) {
//     if (table.contains(key)) {
//         table.borrow_mut(key).push_back(r)
//     } else {
//         table.add(key, vector[r])
//     }
// }
