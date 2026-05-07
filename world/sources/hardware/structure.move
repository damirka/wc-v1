// Define the generic structure that can be used to build any in-game structure
module world::structure;

public struct Structure has key {
    id: UID, // TenantItemId or TenantTypeId 
    // owner_cap: OwnerCap, // OwnerCap<Structure>
    // requirements: vector<Requirement>, // System Requirements (Digital Physics), only admin can add or remove them
}