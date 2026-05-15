/// Service that owns the `SystemAuthorization` rule — "this action must be
/// authorised by the system" (a system cap or sponsor address).
module world::system_service;

use world::request::Request;
use world::requirement::{Self, Requirement};
use world::admin_acl::AdminACL;

/// Marker; only this module can mint `internal::Permit<SystemAuthorization>`.
public struct SystemAuthorization has drop {}

public fun requirement(): Requirement {
    requirement::new<SystemAuthorization>("")
}

public fun is_authorized(req: &mut Request, admin_acl: &AdminACL, ctx: &TxContext) {
    admin_acl.is_authorized_address(ctx.sender());
    req.complete_requirement<SystemAuthorization>(internal::permit());
}
