/// Service that owns the `IsProximity` rule — "this action must be within proximity of a location".
module world::is_proximity;

use world::request::Request;
use world::requirement::{Self, Requirement};

/// Marker; only this module can mint `internal::Permit<IsProximity>`.
public struct IsProximity has drop {}

public fun requirement(): Requirement {
    requirement::new<IsProximity>(vector[])
}

public fun verify_proximity(req: &mut Request, ctx: &TxContext) {
    req.complete_requirement<IsProximity>(internal::permit());
}