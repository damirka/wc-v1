/// Service that owns the `IsProximity` rule — "this action must be within proximity of a location".
module world::jump_permit;

use world::request::Request;
use world::requirement::{Self, Requirement};
use world::structure::Structure;

/// Marker; only this module can mint `internal::Permit<NeedJumpPermit>`.
public struct NeedJumpPermit has drop {}

public struct JumpPermit has key, store {
    id: UID,
    structure_id: ID
}

#[error(code = 0)]
const EPermitWrongStructure: vector<u8> = b"JumpPermit is for a different structure";

public fun requirement(): Requirement {
    requirement::new<NeedJumpPermit>(vector[])
}

public fun verify_need_jump_permit(req: &mut Request, jump_permit: &JumpPermit, ctx: &TxContext) {
    // TODO: verify that the sender has a jump permit
    assert!(req.structure_id() == option::some(jump_permit.structure_id), EPermitWrongStructure);
    req.complete_requirement<NeedJumpPermit>(internal::permit());
}

#[test_only]
public fun mint_jump_permit(structure: &Structure, ctx: &mut TxContext) :JumpPermit {
    let jump_permit = JumpPermit {
        id: object::new(ctx),
        structure_id: object::id(structure),
    };
    jump_permit
}