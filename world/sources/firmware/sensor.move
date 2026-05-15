#[allow(unused)]
module world::sensor;

use world::{request::Request, structure::{Self, Structure, Link}};

use fun attach as Structure.attach_sensor;
use fun link as Structure.link_sensor;

const POWER_REQUIREMENT: u32 = 1000;

public struct Sensor(ID) has store;

public fun new(attachment: ID): Sensor {
    Sensor(attachment)
}

public fun attach(s: &mut Structure, id: ID, ctx: &mut TxContext): Request {
    s.attach_module(Sensor(id), vector[], vector[], vector[], ctx).build(ctx)
}

public fun link(s: &mut Structure, id: ID, ctx: &mut TxContext): (Link, Request) {
    let (link, req) = s.initiate_link(
        id,
        POWER_REQUIREMENT,
        internal::permit<Sensor>(),
        ctx,
    );

    (link, req.build(ctx))
}

public fun in_proximity(_s: &Sensor, _loc: vector<u8>) {}

#[test]
fun test_attach_sensor() {
    let ctx = &mut tx_context::dummy();
    let mut s = structure::new(ctx);
    let s_id = s.id();

    let () = s.attach_sensor(@0.to_id(), ctx).complete_ignore();
    let (link, r) = s.link_sensor(s_id, ctx);

    s.link(link, ctx);
    r.complete_ignore();

    // Sensor doesn't really have a function. Or I think?

    s.destroy();
}
