/obj/item/reagent_container
	name = "Container"
	desc = ""
	icon = 'icons/obj/items/chemistry.dmi'
	icon_state = null
	throwforce = 3
	w_class = SIZE_SMALL
	throw_speed = SPEED_FAST
	throw_range = 5
	attack_speed = 3
	var/amount_per_transfer_from_this = 5
	var/possible_transfer_amounts = list(5,10,15,25,30)
	var/volume = 30
	var/transparent = FALSE //can we see what's in it?
	var/reagent_desc_override = FALSE //does it have a special examining mechanic that should override the normal /reagent_containers examine proc?
	actions_types = list(/datum/action/item_action/reagent_container/set_transfer_amount)
	ground_offset_x = 7
	ground_offset_y = 7

/obj/item/reagent_container/Initialize()
	. = ..()
	create_reagents(volume)

	if(!possible_transfer_amounts)
		actions_types -= /datum/action/item_action/reagent_container/set_transfer_amount

/obj/item/reagent_container/get_examine_text(mob/user)
	. = ..()
	var/reagent_info = show_reagent_info(user)
	if(reagent_info)
		. += reagent_info

/obj/item/reagent_container/proc/show_reagent_info(mob/user)
	if(reagent_desc_override) //custom desc
		return
	if(isxeno(user)) //only humans can see
		return

	if(!reagents) //no reagents datum
		return

	var/distance = get_dist(user, src) //too far away
	if(!(distance > 2 || distance == -1))
		return SPAN_WARNING("It's too far away for you to see what's in it!")

	if(!length(reagents.reagent_list))
		return SPAN_INFO("It contains nothing.")

	if(user.can_see_reagents()) //see exact contents
		return SPAN_INFO("It contains: [reagents.get_reagents_and_amount()]")
	return SPAN_INFO("It contains: [reagents.total_volume]")

/obj/item/reagent_container/proc/set_amount_per_transfer_from_this(mob/living/carbon/human/user)
	if(loc != user)
		return

	var/new_transfer_amount = tgui_input_list(user, "Amount per transfer from this:","[src]", possible_transfer_amounts, 20 SECONDS)
	if(!new_transfer_amount)
		return

	if(loc != user) //check again incase they waited
		return

	amount_per_transfer_from_this = new_transfer_amount

/obj/item/reagent_container/Destroy()
	possible_transfer_amounts = null
	return ..()

/*
// Used on examine for properly skilled people to see contents.
// this is separate from show_reagent_info, as that proc is intended for use with science goggles
// this proc is general-purpose and primarily for medical items that you shouldn't need scigoggles to scan - ie pills, syringes, etc.
*/
/obj/item/reagent_container/proc/display_contents(mob/user)
	if(isxeno(user))
		return

	if(!skillcheck(user, SKILL_MEDICAL, SKILL_MEDICAL_TRAINED))
		return "You don't know what's in it."
	return "It contains: [get_reagent_list_text()]."//this the pill

/// returns a text listing the reagents (and their volume) in the atom. Used by Attack logs for reagents in pills
/obj/item/reagent_container/proc/get_reagent_list_text()
	if(!reagents)
		return "No reagents"
	if(!reagents.reagent_list)
		return "No reagents"
	if(!length(reagents.reagent_list))
		return "No reagents"

	return reagents.get_reagents_and_amount()

// Action for changing the transfer amount of the container
/datum/action/item_action/reagent_container/set_transfer_amount
	name = "Set Transfer Amount"

/datum/action/item_action/reagent_container/set_transfer_amount/New(mob/living/user, obj/item/holder)
	..()
	button.name = name
	button.overlays.Cut()
	var/image/button_overlay = image(holder_item.icon, button, holder_item.icon_state)
	button.overlays += button_overlay

/datum/action/item_action/reagent_container/set_transfer_amount/action_activate()
	var/obj/item/reagent_container/container = holder_item
	container.set_amount_per_transfer_from_this(owner)
