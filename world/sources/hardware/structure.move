/// Generic in-game hardware. A `Structure` is a bare hull: an id, a pointer
/// to its `OwnerCap`, and (in later steps) attached firmware modules and
/// requirement vectors.
module world::structure;

use std::string::String;
use sui::dynamic_field as df;
use world::{
    grid::{Self, Grid},
    location_service,
    request::{Self, RequestBuilder},
    requirement::Requirement
};

const VERSION: u64 = 1;

// TODO : move this to a separate module
public struct OwnerCap has key, store {
    id: UID,
    structure_id: ID,
}

public struct Module<T> has store {
    system_requirements: vector<Requirement>,
    custom_requirements: vector<Requirement>,
    grid_link: Option<ID>,
    actions: vector<String>,
    inner: T,
}

public struct Structure has key {
    id: UID,
    owner_cap_id: ID,
    location_hash: vector<u8>,
}

public struct ModuleKey<phantom T>() has copy, drop, store;
public struct GridKey() has copy, drop, store;

// === Connectors ===

///
public(package) fun attach_grid<T: store>(s: &mut Structure, grid: T, ctx: &mut TxContext) {
    df::add(&mut s.id, GridKey(), grid)
}

public fun attach_module<T: store>(
    s: &mut Structure,
    inner: T,
    actions: vector<String>,
    system_requirements: vector<Requirement>,
    custom_requirements: vector<Requirement>,
    _ctx: &mut TxContext,
): RequestBuilder {
    df::add(
        &mut s.id,
        ModuleKey<T>(),
        Module {
            system_requirements,
            custom_requirements,
            grid_link: option::none(),
            actions,
            inner,
        },
    );

    request::new("attach")
        .with_version(VERSION)
        .with_structure_id(s.id.to_inner())
        .with_requirement(location_service::requirement(s.location_hash))
}

/// Standard trigger for interaction, gives access to the internal T of the Module.
public fun interact<T: store>(
    s: &mut Structure,
    name: String,
    _: internal::Permit<T>,
    _ctx: &mut TxContext,
): (&mut Module<T>, RequestBuilder) {
    let structure_id = s.id.to_inner();
    let mut request = request::new(name).with_version(VERSION).with_structure_id(structure_id);
    let mod = df::borrow_mut<_, Module<T>>(&mut s.id, ModuleKey<T>());

    mod.system_requirements.do_ref!(|req| request = request.with_requirement(*req));
    mod.custom_requirements.do_ref!(|req| request = request.with_requirement(*req));

    (mod, request)
}

public fun initiate_link<T: store>(
    s: &mut Structure,
    to: ID,
    amt: u32,
    _: internal::Permit<T>,
    _ctx: &mut TxContext,
): (Link, RequestBuilder) {
    let structure_id = s.id();
    let mod = df::borrow_mut<_, Module<T>>(&mut s.id, ModuleKey<T>());

    mod.grid_link.fill(to);

    (
        Link(to, amt),
        request::new("link")
            .with_version(VERSION)
            .with_structure_id(structure_id)
            .with_requirement(location_service::requirement(s.location_hash)),
    )
}

public fun link(s: &mut Structure, link: Link, _ctx: &mut TxContext) {
    let structure_id = s.id();
    let g: &mut Grid = df::borrow_mut(&mut s.id, GridKey());
    let Link(id, amt) = link;

    assert!(structure_id == id);
    g.reserve(amt);
}

// === Accessors ===

public fun id(s: &Structure): ID { object::id(s) }

public fun owner_cap_id(s: &Structure): ID { s.owner_cap_id }

public fun structure_id_of(cap: &OwnerCap): ID { cap.structure_id }

public fun inner<T>(s: &Module<T>): &T { &s.inner }

public fun inner_mut<T>(s: &mut Module<T>): &mut T { &mut s.inner }

// === For Testing ===

public(package) fun new(ctx: &mut TxContext): Structure {
    Structure {
        id: object::new(ctx),
        owner_cap_id: ctx.fresh_object_address().to_id(),
        location_hash: vector[],
    }
}

public(package) fun destroy(s: Structure) {
    let Structure { id, .. } = s;
    id.delete();
}
