module world::admin_acl;

use sui::table::{Self, Table};

public struct AdminACL has key {
    id: UID,
    authorized_addresses: Table<address, bool>,
}

#[error(code = 0)]
const ENotAuthorized: vector<u8> = "Not authorized";

public fun add_authorized_address(admin_acl: &mut AdminACL, addr: address, ctx: &TxContext) {
    assert!(is_authorized_address(admin_acl, ctx.sender()), ENotAuthorized);
    admin_acl.authorized_addresses.add(addr, true);
}

public fun remove_authorized_address(admin_acl: &mut AdminACL, addr: address, ctx: &TxContext) {
    assert!(is_authorized_address(admin_acl, ctx.sender()), ENotAuthorized);
    admin_acl.authorized_addresses.remove(addr);
}

public fun is_authorized_address(admin_acl: &AdminACL, addr: address): bool {
    admin_acl.authorized_addresses.contains(addr)
}

fun init(ctx: &mut TxContext) {
    let mut admin_acl = AdminACL { id: object::new(ctx), authorized_addresses: table::new(ctx) };
    admin_acl.authorized_addresses.add(ctx.sender(), true);
    transfer::share_object(admin_acl);
}

#[test_only]
public fun create_for_testing(ctx: &mut TxContext): AdminACL {
    let mut admin_acl = AdminACL { id: object::new(ctx), authorized_addresses: table::new(ctx) };
    admin_acl.authorized_addresses.add(ctx.sender(), true);
    admin_acl
}

#[test_only]
public fun destroy_for_testing(admin_acl: AdminACL) {
    let AdminACL { id, authorized_addresses } = admin_acl;
    authorized_addresses.drop();
    id.delete();
}
