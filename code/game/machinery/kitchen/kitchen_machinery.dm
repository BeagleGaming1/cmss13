#define COOKING_DAMAGE_OPERATIONAL 0
#define COOKING_DAMAGE_SCREWDRIVER 1
#define COOKING_DAMAGE_WRENCH 2

/obj/structure/machinery/kitchen
	name = "abstract cooking device"
	icon = 'icons/obj/structures/machinery/kitchen/kitchen_32x32.dmi'
	density = TRUE
	anchored = TRUE
	use_power = USE_POWER_IDLE
	throwpass = FALSE

	///The icon state used for all
	var/base_icon_state
	///If the machine is broken and needs repairs
	var/broken = COOKING_DAMAGE_OPERATIONAL
	///What the machine can cook
	var/cooking_flags = COOKING_TYPE_ALL_RECIPES

/obj/structure/machinery/kitchen/Initialize(mapload, ...)
	. = ..()
	if(!cooking_flags)
		CRASH("[src] is missing cooking_flags!")
	AddComponent(/datum/component/cooking, cooking_flags)
	RegisterSignal(src, COMSIG_COOKING_MACHINE_STATE, PROC_REF(update_sprites))

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
	if(prob(5))
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

///Change the sprite based on whether the machine is on/off and whether it is cooking something
/obj/structure/machinery/kitchen/proc/update_sprites(source, datum/component/cooking/cooking)
	SIGNAL_HANDLER

	if(!base_icon_state)
		return
	var/functioning = cooking.functioning
	var/operating = cooking.operating
	var/state = cooking.cooking_state

	if(state >= COOKING_STATE_BURN)
		var/image/image
		switch(state)
			if(COOKING_STATE_BURN)
				image = image(icon = 'icons/obj/structures/machinery/kitchen/kitchen_32x32.dmi', icon_state = "smoking")
			if(COOKING_STATE_FIRE)
				image = image(icon = 'icons/obj/structures/machinery/kitchen/kitchen_32x32.dmi', icon_state = "burning")

		return

	if(!functioning)
		icon_state = "[base_icon_state]_off"
		return
	if(operating)
		icon_state = "[base_icon_state]_on"
		return
	icon_state = base_icon_state

#undef COOKING_DAMAGE_OPERATIONAL
#undef COOKING_DAMAGE_SCREWDRIVER
#undef COOKING_DAMAGE_WRENCH

/obj/structure/machinery/kitchen/debug //REMOVE THIS
	name = "DEBUG"
	icon_state = "DEBUG"

/obj/structure/machinery/kitchen/microwave
	name = "microwave"
	cooking_flags = COOKING_TYPE_MICROWAVE
	base_icon_state = "microwave"
	icon_state = "microwave_off"

/obj/structure/machinery/kitchen/grill
	name = "grill"
	cooking_flags = COOKING_TYPE_GRILL
	base_icon_state = "grill_colony"
	icon_state = "grill_colony_off"

/obj/structure/machinery/kitchen/grill/ship
	icon = 'icons/obj/structures/machinery/kitchen/kitchen_64x32.dmi'
	base_icon_state = "grill_ship"
	icon_state = "grill_ship_off"

/obj/structure/machinery/kitchen/griddle
	name = "griddle"
	cooking_flags = COOKING_TYPE_GRIDDLE
	base_icon_state = "griddle_colony"
	icon_state = "griddle_colony_off"

/obj/structure/machinery/kitchen/griddle/ship
	icon = 'icons/obj/structures/machinery/kitchen/kitchen_64x32.dmi'
	base_icon_state = "griddle_ship"
	icon_state = "griddle_ship_off"

/obj/structure/machinery/kitchen/oven
	name = "oven"
	cooking_flags = COOKING_TYPE_OVEN
	base_icon_state = "oven_mini"
	icon_state = "oven_mini_off"

/obj/structure/machinery/kitchen/oven/ship
	icon = 'icons/obj/structures/machinery/kitchen/kitchen_64x64.dmi'
	base_icon_state = "oven_ship"
	icon_state = "oven_ship_off"

/obj/structure/machinery/kitchen/stove
	name = "stove"
	cooking_flags = COOKING_TYPE_STOVE
	icon = 'icons/obj/structures/machinery/kitchen/kitchen_64x32.dmi'
	base_icon_state = "stove"
	icon_state = "stove_off"

/obj/structure/machinery/kitchen/stove/update_sprites(source, datum/component/cooking/cooking)
	. = ..()
	if(!cooking.ingredients.len)
		return

	icon_state = "[base_icon_state]_pots"

/obj/structure/machinery/kitchen/duo
	name = "range"
	cooking_flags = COOKING_TYPE_STOVE|COOKING_TYPE_OVEN
	base_icon_state = "duo"
	icon_state = "duo_off"

//hi chat
