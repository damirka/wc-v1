/// Generic in-game hardware. A `Structure` is a bare hull: an id, a pointer
/// to its `OwnerCap`, and (in later steps) attached firmware modules and
/// requirement vectors.
module world::structure;

use world::request::{Self, Request};
use world::requirement::Requirement;
use sui::table::{Self, Table};
use std::type_name::{Self, TypeName};
use world::system_service::{Self, SystemAuthorization};
use world::admin_acl::AdminACL;
use sui::dynamic_field as df;

// Common requirements for all structures
public struct StructureConfig has key, store {
    id: UID,
    requirements: Table<TypeName, vector<Requirement>>, // can be renamed structure/system requirement
}

public struct Structure has key {
    id: UID,
    owner_cap_id: ID,
    //requirements: Table<TypeName, vector<Requirement>> // per structure requirements
}

public struct ModuleKey<phantom T>() has copy, drop, store;

// TODO : move this to a separate module
public struct OwnerCap has key, store {
    id: UID,
    structure_id: ID,
}

#[error(code = 0)]
const ENotAuthorized: vector<u8> = b"Not authorized";
#[error(code = 2)]
const EModuleAlreadyAttached: vector<u8> = b"Firmware already attached";
#[error(code = 3)]
const EModuleNotAttached: vector<u8> = b"Firmware not attached";

// This is a action marker typeName for the Anchor action. We need this to add requirements per action
public struct Anchor has drop {}

#[allow(lint(self_transfer))]
public fun anchor(cfg: &StructureConfig, ctx: &mut TxContext): (Structure, Request) {
    let s_uid = object::new(ctx);
    let s_id  = s_uid.to_inner();
    let cap = OwnerCap { id: object::new(ctx), structure_id: s_id };
    let s = Structure { id: s_uid, owner_cap_id: object::id(&cap) };
    let req = request::new(
        b"structure:anchor".to_string(),
        option::some(object::id(&s)),
        default_requirement<Anchor>(cfg), 
    );
    transfer::transfer(cap, ctx.sender());
    (s, req)
}

public fun share(s: Structure) {
    transfer::share_object(s);
}

public fun attach_module<T:  store>(s: &mut Structure, admin_acl: &AdminACL, _: internal::Permit<T>, state: T, ctx: &mut TxContext) {
    assert!(admin_acl.is_authorized_address(ctx.sender()), ENotAuthorized);
    let key = ModuleKey<T>();
    assert!(!df::exists_(&s.id, key), EModuleAlreadyAttached);
    df::add(&mut s.id, key, state);
}

public fun detach_module<T: store>(s: &mut Structure, admin_acl: &AdminACL, _: internal::Permit<T>, ctx: &mut TxContext): T {
    assert!(admin_acl.is_authorized_address(ctx.sender()), ENotAuthorized);
    let key = ModuleKey<T>();
    assert!(df::exists_(&s.id, key), EModuleNotAttached);
    df::remove<ModuleKey<T>, T>(&mut s.id, key)
}

// can this also made a request ?
public fun add_requirement<A>(
    cfg: &mut StructureConfig,
    acl: &AdminACL,
    r: Requirement,
    ctx: &TxContext,
) {
    assert!(acl.is_authorized_address(ctx.sender()), ENotAuthorized);
    let key = type_name::with_original_ids<A>();
    if (cfg.requirements.contains(key)) {
        cfg.requirements.borrow_mut(key).push_back(r);
    } else {
        cfg.requirements.add(key, vector[r]);
    };
}

public fun remove_requirement<A>(
    cfg: &mut StructureConfig, acl: &AdminACL, r: Requirement, ctx: &TxContext,
) {
    assert!(acl.is_authorized_address(ctx.sender()), ENotAuthorized);
    let key = type_name::with_original_ids<A>();
    let reqs = cfg.requirements.borrow_mut(key);
    let target = r;
    let idx = reqs.find_index!(|x| x == target);
    if (idx.is_some()) {
        reqs.swap_remove(idx.destroy_some());
    }
}

public(package) fun default_requirement<A>(cfg: &StructureConfig): vector<Requirement> {
    let key = type_name::with_original_ids<A>();
    if (cfg.requirements.contains(key)) *cfg.requirements.borrow(key)
    else vector[]
}

public fun owner_cap_id(s: &Structure): ID { s.owner_cap_id }
public fun structure_id_of(cap: &OwnerCap): ID { cap.structure_id }

public fun module_state<T:  store>(s: &Structure, _: internal::Permit<T>): &T {
    df::borrow(&s.id, ModuleKey<T>())
}

public fun module_state_mut<T:  store>(s: &mut Structure, _: internal::Permit<T>): &mut T {
    df::borrow_mut(&mut s.id, ModuleKey<T>())
}

fun init(ctx: &mut TxContext) {
    let mut cfg = StructureConfig { id: object::new(ctx), requirements: table::new(ctx) };
    cfg.requirements.add(
        type_name::with_original_ids<Anchor>(),
        vector[system_service::requirement()],
    );
    transfer::share_object(cfg);
}

#[test_only]
public fun init_for_testing(ctx: &mut TxContext) {
    init(ctx);
}
