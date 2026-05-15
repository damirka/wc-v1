/// Service that owns the `IsProximity` rule — "this action must be within proximity of a location".
module world::location_service;

use world::{request::Request, requirement::{Self, Requirement}};

/// Marker; only this module can mint `internal::Permit<IsProximity>`.
public struct IsProximity(vector<u8>) has drop;

public fun requirement(loc: vector<u8>): Requirement {
    requirement::from_config(IsProximity(loc))
}

public fun verify_proximity(req: &mut Request, _ctx: &mut TxContext) {
    req.complete_requirement<IsProximity>(internal::permit());
}
