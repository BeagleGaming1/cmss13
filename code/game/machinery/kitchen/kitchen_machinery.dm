#define COOKING_DAMAGE_OPERATIONAL 0
#define COOKING_DAMAGE_SCREWDRIVER 1
#define COOKING_DAMAGE_WRENCH 2

/obj/structure/machinery/kitchen
	name = "abstract cooking device"
	icon = 'icons/obj/structures/machinery/kitchen.dmi'
	density = TRUE
	anchored = TRUE
	use_power = USE_POWER_IDLE
	throwpass = FALSE

	///If the machine is broken and needs repairs
	var/broken = COOKING_DAMAGE_OPERATIONAL

	///What the machine can cook
	var/cooking_type = COOKING_TYPE_ALL_RECIPES

/obj/structure/machinery/kitchen/Initialize(mapload, ...)
	. = ..()
	if(!cooking_type)
		CRASH("[src] is missing a cooking_type!")
	AddComponent(/datum/component/cooking, cooking_type)

/obj/structure/machinery/kitchen/get_examine_text(mob/user)
	. = ..()
	switch(broken)
		if(COOKING_DAMAGE_SCREWDRIVER)
			. += SPAN_INFO("It requires a screwdriver to repair.")
		if(COOKING_DAMAGE_WRENCH)
			. += SPAN_INFO("It requires a wrench to start repairing.")

/obj/structure/machinery/kitchen/attackby(obj/item/attacking_item, mob/user)
	if(broken)
		if(broken == COOKING_DAMAGE_SCREWDRIVER && HAS_TRAIT(attacking_item, TRAIT_TOOL_SCREWDRIVER))
			if(!do_after(user, 10 SECONDS, INTERRUPT_ALL, BUSY_ICON_BUILD, src))
				return
			to_chat(user, SPAN_NOTICE("You finish repairing [src] with [attacking_item]."))
			damage_machine(-1)

		if(broken == COOKING_DAMAGE_WRENCH && HAS_TRAIT(attacking_item, TRAIT_TOOL_WRENCH))
			if(!do_after(user, 10 SECONDS, INTERRUPT_ALL, BUSY_ICON_BUILD, src))
				return
			to_chat(user, SPAN_NOTICE("You start to repair [src] with [attacking_item]."))
			damage_machine(-1)
		return
	. = ..()

/obj/structure/machinery/kitchen/ex_act(severity)
	if(indestructible)
		return

	switch(severity)
		if(0 to EXPLOSION_THRESHOLD_LOW)
			damage_machine(prob(25))
		if(EXPLOSION_THRESHOLD_LOW to EXPLOSION_THRESHOLD_MEDIUM)
			damage_machine(pick(25;0, 50;1, 25;2))
		if(EXPLOSION_THRESHOLD_MEDIUM to INFINITY)
			damage_machine(rand(1, 2))

/obj/structure/machinery/kitchen/bullet_act(obj/projectile/P)
	. = ..()
	if(indestructible)
		return
	if(prob(1))
		damage_machine(1)

/obj/structure/machinery/kitchen/proc/damage_machine(damage_severity, silent = FALSE)
	if(!damage_severity)
		return
	var/old_broken = broken
	broken = clamp(broken + damage_severity, COOKING_DAMAGE_OPERATIONAL, COOKING_DAMAGE_WRENCH)

	if(broken <= old_broken) //if it was fixed
		return
	if(silent)
		return
	var/datum/effect_system/spark_spread/sparks = new
	sparks.set_up(rand(1,5), TRUE, src)
	sparks.start()

#undef COOKING_DAMAGE_OPERATIONAL
#undef COOKING_DAMAGE_SCREWDRIVER
#undef COOKING_DAMAGE_WRENCH

/obj/structure/machinery/kitchen/microwave
	cooking_type = COOKING_TYPE_MICROWAVE
	icon_state = "mw"
