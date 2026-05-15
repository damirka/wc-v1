module world::turret;

use world::{grid, location_service, request::Request, structure::Structure};

use fun attach as Structure.attach_turret;
use fun shoot as Structure.shoot;
use fun link as Structure.link_turret;

const SHOOT_POWER_REQ: u32 = 1000;
const ACTIONS: vector<vector<u8>> = vector["shoot"];

public struct Turret() has store;

/// Attach the module to a structure.
public fun attach(s: &mut Structure, ctx: &mut TxContext): Request {
    s
        .attach_module(
            Turret(),
            ACTIONS.map!(|a| a.to_string()),
            vector[grid::is_powered_requirement()],
            vector[],
            ctx,
        )
        .build(ctx)
}

/// Perform a shoot action in the given direction.
public fun shoot(s: &mut Structure, loc: vector<u8>, ctx: &mut TxContext): Request {
    let (_turret, req) = s.interact("shoot", internal::permit<Turret>(), ctx);
    req
        .with_requirement(location_service::requirement(loc))
        .with_requirement(grid::available_power(SHOOT_POWER_REQ))
        .build(ctx)
}

public fun link(s: &mut Structure, id: ID, ctx: &mut TxContext): (Link, Request) {
    let (link, req) = s.initiate_link(
        id,
        SHOOT_POWER_REQ,
        internal::permit<Sensor>(),
        ctx,
    );

    (link, req.build(ctx))
}

#[test]
fun test_turret_is_powered() {
    use world::structure;

    let ctx = &mut tx_context::dummy();
    let mut s = structure::new(ctx);
    let s_id = s.id();

    // Create a Grid instance.
    s.attach_grid(ctx);

    // There may be a request eventually.
    let () = s.attach_turret(ctx).complete_ignore();

    let (link, r) = s.link_turret(s_id, ctx);

    let r = s.link(link, ctx);
    let r = s.shoot("", ctx);

    // IsPowered(ID)

    r.complete_ignore(); // TODO!
    s.destroy();
}

// Notes, todos:
// - each action comes with a power requirement — what do we do?
// - I guess we just "do" it?
