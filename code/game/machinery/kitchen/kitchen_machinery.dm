/obj/structure/machinery/kitchen
	name = "abstract cooking device"
	icon = 'icons/obj/structures/machinery/kitchen/kitchen_32x32.dmi'
	density = TRUE
	anchored = TRUE
	use_power = USE_POWER_IDLE
	throwpass = FALSE

	icon_state = "DEBUG" //REMOVE THIS LATER

	///The icon state used for all
	var/base_icon_state = COOKING_TYPE_ALL_RECIPES
	///What the machine can cook
	var/cooking_flags = NO_FLAGS
	var/pixel_x_overlay_offset = 0
	var/pixel_y_overlay_offset = 0

/obj/structure/machinery/kitchen/Initialize(mapload, ...)
	. = ..()
	if(!cooking_flags)
		CRASH("[src] is missing cooking_flags!")
	AddComponent(/datum/component/cooking, cooking_flags)
	RegisterSignal(src, COMSIG_COOKING_MACHINE_STATE, PROC_REF(update_sprites))

///Change the sprite based on whether the machine is on/off and whether it is cooking something
/obj/structure/machinery/kitchen/proc/update_sprites(source, datum/component/cooking/cooking)
	SIGNAL_HANDLER

	if(!base_icon_state)
		return
	. = TRUE

	var/functioning = cooking.functioning
	var/operating = cooking.operating
	var/state = cooking.cooking_state

	overlays.Cut()

	if(state >= COOKING_STATE_BURN)
		var/image/smoke_overlay
		switch(state)
			if(COOKING_STATE_BURN)
				smoke_overlay = image(icon = 'icons/obj/structures/machinery/kitchen/kitchen_32x32.dmi', icon_state = "smoking")
			if(COOKING_STATE_FIRE)
				smoke_overlay = image(icon = 'icons/obj/structures/machinery/kitchen/kitchen_32x32.dmi', icon_state = "burning")
		overlays += smoke_overlay

	if(!functioning)
		icon_state = "[base_icon_state]_off"
		return
	if(operating)
		icon_state = "[base_icon_state]_on"
		return
	icon_state = base_icon_state

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
	bound_x = 32

/obj/structure/machinery/kitchen/griddle
	name = "griddle"
	cooking_flags = COOKING_TYPE_GRIDDLE
	base_icon_state = "griddle_colony"
	icon_state = "griddle_colony_off"

/obj/structure/machinery/kitchen/griddle/ship
	icon = 'icons/obj/structures/machinery/kitchen/kitchen_64x32.dmi'
	base_icon_state = "griddle_ship"
	icon_state = "griddle_ship_off"
	bound_x = 32

/obj/structure/machinery/kitchen/oven
	name = "oven"
	cooking_flags = COOKING_TYPE_OVEN
	base_icon_state = "oven_mini"
	icon_state = "oven_mini_off"

/obj/structure/machinery/kitchen/oven/ship
	icon = 'icons/obj/structures/machinery/kitchen/kitchen_64x64.dmi'
	base_icon_state = "oven_ship"
	icon_state = "oven_ship_off"
	bound_x = 32

/obj/structure/machinery/kitchen/oven/ship/update_icon(source, datum/component/cooking/cooking)
	. = ..()

	if(!.)
		return

	var/functioning = cooking.functioning
	var/operating = cooking.operating

	var/image/oven_top //please tell me theres a better way to do this
	if(!functioning)
		oven_top = image(icon_state = "[base_icon_state]_off_top")
	else if(operating)
		oven_top = image(icon_state = "[base_icon_state]_on_top")
	else
		oven_top = image(icon_state = "[base_icon_state]_top")
	oven_top.layer = ABOVE_XENO_LAYER
	overlays += oven_top

/obj/structure/machinery/kitchen/stove
	name = "stove"
	cooking_flags = COOKING_TYPE_STOVE
	icon = 'icons/obj/structures/machinery/kitchen/kitchen_64x32.dmi'
	base_icon_state = "stove"
	icon_state = "stove_off"
	bound_x = 32

/obj/structure/machinery/kitchen/stove/Initialize(mapload, ...)
	. = ..()
	RegisterSignal(src, COMSIG_COOKING_MACHINE_ATTEMPT_ADD, PROC_REF(attempt_add_ingredient))

/obj/structure/machinery/kitchen/stove/update_icon(source, datum/component/cooking/cooking)
	. = ..()

	if(!.)
		return

	var/ingredient_amount = min(cooking.ingredients.len, 4)
	if(!ingredient_amount)
		return

	var/image/stove_pots
	stove_pots += image(icon_state = "[base_icon_state]_pots_[ingredient_amount]")
	overlays += stove_pots

/obj/structure/machinery/kitchen/stove/proc/attempt_add_ingredient(source, datum/component/cooking/cooking, mob/living/carbon/human/user, obj/item/attacking_item)
	SIGNAL_HANDLER

	if(!istype(attacking_item, /obj/item)) //TODO restrict to pots and pans
		return COMPONENT_COOKING_MACHINE_CANCEL_ADD

/obj/structure/machinery/kitchen/duo
	name = "range"
	cooking_flags = COOKING_TYPE_STOVE|COOKING_TYPE_OVEN
	base_icon_state = "duo"
	icon_state = "duo_off"

/obj/structure/machinery/kitchen/processor
	name = "processor"
	cooking_flags = COOKING_TYPE_PROCESSOR
	base_icon_state = "processor"
	icon_state = "processor_off"

/obj/structure/machinery/kitchen/gibber
	name = "gibber"
	cooking_flags = COOKING_TYPE_GIBBER
	base_icon_state = "gibber"
	icon_state = "gibber_off"

//hi chat
