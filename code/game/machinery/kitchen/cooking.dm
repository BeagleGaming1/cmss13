#define COOKING_TYPE_ALL_RECIPES "cooking_type_all_recipes"
#define COOKING_TYPE_MICROWAVE "cooking_type_microwave"
#define COOKING_TYPE_OVEN "cooking_type_oven" //why do they call it oven when you of in the cold food of out hot eat the food
#define COOKING_TYPE_GRILL "cooking_type_grill"
#define COOKING_TYPE_GRIDDLE "cooking_type_griddle"
#define COOKING_TYPE_STOVE "cooking_type_stove"
#define COOKING_TYPE_CAMPFIRE "cooking_type_campfire"
#define COOKING_TYPE_PROCESSOR "cooking_type_processor"

#define COOKING_METHOD_NONE "cooking_method_none"
#define COOKING_METHOD_PLATE "cooking_method_plate"
#define COOKING_METHOD_PAN "cooking_method_pan"
#define COOKING_METHOD_POT "cooking_method_pot"

/datum/component/cooking
	dupe_mode = COMPONENT_DUPE_UNIQUE

	///structure storing the component
	var/obj/structure/source_atom
	///External factors that may be stopping the item from cooking
	var/functioning = FALSE
	///Whether the machine is currently making food
	var/operating = FALSE

	///What categories of food can be cooked from it
	var/cooking_type
	///What items will be used to cook with
	var/list/ingredients = list()

	///All the recipes that can be cooked
	var/global/list/datum/recipe/available_recipes

/datum/component/cooking/Initialize(cooking_type, ...)
	. = ..()
	if(!isStructure(parent))
		return COMPONENT_INCOMPATIBLE
	if(!cooking_type)
		return COMPONENT_INCOMPATIBLE

	source_atom = parent
	src.cooking_type = cooking_type

	RegisterSignal(source_atom, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(source_atom, COMSIG_ATOM_CLICKED, PROC_REF(interact_with))
	RegisterSignal(source_atom, COMSIG_STRUCTURE_ATTACKBY, PROC_REF(attempt_add_ingredients))
	RegisterSignal(source_atom, COMSIG_STRUCTURE_PRE_TOGGLE_ANCHOR, PROC_REF(check_wrenchability))

	if(available_recipes)
		return

	initialize_recipes()

/datum/component/cooking/Destroy(force, silent)
	for(var/i in 1 to ingredients) //dump all the ingredients when destroyed
		var/obj/ingredient = remove_last_ingredient() //not delete, so you cant destroy important stuff in there
		ingredient.forceMove(get_turf(source_atom))

	. = ..()

///Set the global list of all available recipes
/datum/component/cooking/proc/initialize_recipes()
	if(available_recipes) //if called manually, delete the current list
		QDEL_NULL_LIST(available_recipes)

	available_recipes = new
	for(var/new_recipe in (typesof(/datum/recipe)-/datum/recipe))
		available_recipes += new new_recipe


///Adds examine text to the machine
/datum/component/cooking/proc/on_examine(source, mob/user, list/examine_text)
	SIGNAL_HANDLER
	if(!ishuman(user))
		return

	if(!functioning)
		examine_text += "It is off."
		return

	if(operating)
		examine_text += "It is currently making something."

	var/food_selection = ""
	var/chem_selection = ""
	for(var/atom/food in ingredients)
		if(food_selection != "")
			food_selection += ", "
		food_selection += "\a [food]"
		var/chemicals = food.reagents?.get_reagents_and_amount()
		if(chemicals)
			if(chem_selection != "")
				chem_selection += ", "
			chem_selection += chemicals

	if(food_selection)
		examine_text += "It has [food_selection]."
	if(skillcheck(user, SKILL_DOMESTIC, SKILL_DOMESTIC_MASTER))
		if(chem_selection)
			examine_text += "It has [chem_selection]."

///Prevents the machine from being unwrenched if there is something in it
/datum/component/cooking/proc/check_wrenchability(source, obj/item/wrench, mob/user)
	SIGNAL_HANDLER

	if(!(functioning || operating || ingredients.len)) //dont unanchor if theres something in there, no bottomless crates
		return
	to_chat(user, SPAN_WARNING("You fail to unanchor [source]."))
	return COMPONENT_CANCEL_TOGGLE_ANCHOR

///Leads to other effects of clicking the machine
/datum/component/cooking/proc/interact_with(source, mob/user, proximity, list/mods)
	SIGNAL_HANDLER
	if(!proximity)
		return

	if((mods[ALT_CLICK]) || (mods[SHIFT_CLICK] && !mods[MIDDLE_CLICK])) //do the normal things if theres the standard click mods
		return

	if(!ishuman(user))
		return

	if(operating || !source_atom.anchored)
		to_chat(user, SPAN_NOTICE("You cannot interact with [source] at this time."))
		return

	if(mods[CTRL_CLICK]) //Ctrl click to toggle on / off
		toggle_functioning(user)
		return COMPONENT_ATOM_OVERRIDE_CLICK

	if(!functioning)
		return

	switch(user.a_intent)
		if(INTENT_HELP)
			return //continues to attempt_add_ingredients()

		if(INTENT_DISARM)
			start_cooking(user)

		if(INTENT_GRAB)
			extra_functionality(user)

		if(INTENT_HARM)
			remove_ingredients(user)

	return COMPONENT_ATOM_OVERRIDE_CLICK

///Toggles whether the machine can be used for cooking
/datum/component/cooking/proc/toggle_functioning(mob/user)
	functioning = !functioning
	to_chat(user, SPAN_NOTICE("You [functioning ? "enable" : "disable"] [source_atom]."))

///Add an ingredient to the machines contents and ingredients list from the mobs hand
/datum/component/cooking/proc/attempt_add_ingredients(source, obj/item/attacking_item, mob/user)
	SIGNAL_HANDLER

	if(!functioning || operating)
		return

	if(attacking_item.flags_item & ITEM_ABSTRACT)
		return

	if(istype(attacking_item, /obj/item/stack))
		var/obj/item/stack/stack = attacking_item
		if(stack.amount != 1)
			to_chat(user, SPAN_NOTICE("You can only put one of [stack] in [source] at a time."))
			return

	if(!user.drop_inv_item_to_loc(attacking_item, source))
		to_chat(user, SPAN_NOTICE("You fail to put [attacking_item] in [source]."))
		return

	ingredients += attacking_item
	user.visible_message("[user] adds [attacking_item] to [source].", "You add [attacking_item] to [source].")
	return COMPONENT_NO_AFTERATTACK

///Turn the ingredients into food
/datum/component/cooking/proc/start_cooking(mob/user)
	return //todo

///Any extra functions that the machine might have
/datum/component/cooking/proc/extra_functionality(mob/user)
	return

///Put the ingredients into the user's hands or the floor
/datum/component/cooking/proc/remove_ingredients(mob/user)
	if(!ingredients.len)
		to_chat(user, SPAN_NOTICE("There are no ingredients for you to remove."))
		return

	var/obj/last_ingredient = remove_last_ingredient()
	if(!last_ingredient)
		to_chat(user, SPAN_NOTICE("You fail to remove a ingredient."))
		return

	if(!user.put_in_hands(last_ingredient))
		last_ingredient.forceMove(get_turf(source_atom))

//Remove ingredients from the machine, return the ingredient
/datum/component/cooking/proc/remove_last_ingredient()
	var/obj/last_ingredient = ingredients[ingredients.len]

	if(QDELETED(last_ingredient)) //Shouldnt be possible, but just incase someone breaks it, remove it
		ingredients -= last_ingredient
		return

	ingredients -= last_ingredient
	return last_ingredient
